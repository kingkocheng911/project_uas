alter table public.wallet_topups
  add column if not exists provider_order_id text,
  add column if not exists provider_transaction_id text,
  add column if not exists provider_payment_type text,
  add column if not exists provider_payment_code text,
  add column if not exists provider_va_number text,
  add column if not exists provider_bank text,
  add column if not exists provider_qr_url text,
  add column if not exists provider_status text,
  add column if not exists provider_response jsonb not null default '{}'::jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'wallet_topups_provider_response_is_object'
  ) then
    alter table public.wallet_topups
      add constraint wallet_topups_provider_response_is_object
      check (jsonb_typeof(provider_response) = 'object');
  end if;
end
$$;

create unique index if not exists wallet_topups_provider_order_id_key
on public.wallet_topups (provider_order_id)
where provider_order_id is not null;

create or replace function public.apply_wallet_topup_provider_status(
  p_topup_id uuid,
  p_provider_status text,
  p_provider_transaction_id text default null,
  p_provider_payment_type text default null,
  p_provider_payment_code text default null,
  p_provider_va_number text default null,
  p_provider_bank text default null,
  p_provider_qr_url text default null,
  p_provider_response jsonb default '{}'::jsonb,
  p_paid_at timestamptz default null,
  p_expires_at timestamptz default null
)
returns table (
  topup_id uuid,
  status text,
  wallet_balance integer,
  paid_at timestamptz,
  expires_at timestamptz,
  already_processed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_topup public.wallet_topups%rowtype;
  v_next_status text;
  v_wallet_balance integer := 0;
  v_already_processed boolean := false;
begin
  select *
  into v_topup
  from public.wallet_topups
  where id = p_topup_id
  for update;

  if not found then
    raise exception 'Transaksi top up tidak ditemukan';
  end if;

  v_next_status := case lower(coalesce(p_provider_status, ''))
    when 'capture' then 'paid'
    when 'settlement' then 'paid'
    when 'pending' then 'pending'
    when 'deny' then 'failed'
    when 'failure' then 'failed'
    when 'cancel' then 'cancelled'
    when 'expire' then 'expired'
    when 'refund' then 'failed'
    when 'partial_refund' then 'failed'
    else v_topup.status
  end;

  if v_topup.status = 'paid' then
    v_already_processed := true;
  end if;

  update public.wallet_topups
  set
    status = v_next_status,
    provider_status = coalesce(p_provider_status, provider_status),
    provider_transaction_id = coalesce(p_provider_transaction_id, provider_transaction_id),
    provider_payment_type = coalesce(p_provider_payment_type, provider_payment_type),
    provider_payment_code = coalesce(p_provider_payment_code, provider_payment_code),
    provider_va_number = coalesce(p_provider_va_number, provider_va_number),
    provider_bank = coalesce(p_provider_bank, provider_bank),
    provider_qr_url = coalesce(p_provider_qr_url, provider_qr_url),
    provider_response = coalesce(p_provider_response, '{}'::jsonb),
    paid_at = case
      when v_topup.status <> 'paid' and v_next_status = 'paid' then coalesce(p_paid_at, now())
      else public.wallet_topups.paid_at
    end,
    expires_at = coalesce(p_expires_at, public.wallet_topups.expires_at)
  where id = v_topup.id;

  if v_topup.status <> 'paid' and v_next_status = 'paid' then
    update public.profiles
    set wallet_balance = public.profiles.wallet_balance + v_topup.amount
    where id = v_topup.user_id
    returning public.profiles.wallet_balance into v_wallet_balance;
  else
    select p.wallet_balance
    into v_wallet_balance
    from public.profiles p
    where p.id = v_topup.user_id;
  end if;

  return query
  select
    v_topup.id,
    v_next_status,
    coalesce(v_wallet_balance, 0),
    case
      when v_topup.status <> 'paid' and v_next_status = 'paid' then coalesce(p_paid_at, now())
      else v_topup.paid_at
    end,
    coalesce(p_expires_at, v_topup.expires_at),
    v_already_processed;
end;
$$;

grant execute on function public.apply_wallet_topup_provider_status(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  timestamptz,
  timestamptz
) to service_role;
