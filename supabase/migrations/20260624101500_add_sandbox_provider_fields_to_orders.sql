alter table public.orders
  add column if not exists provider_order_id text,
  add column if not exists provider_transaction_id text,
  add column if not exists provider_payment_type text,
  add column if not exists provider_payment_code text,
  add column if not exists provider_va_number text,
  add column if not exists provider_bank text,
  add column if not exists provider_qr_url text,
  add column if not exists provider_status text,
  add column if not exists provider_response jsonb not null default '{}'::jsonb,
  add column if not exists payment_expires_at timestamptz,
  add column if not exists payment_paid_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_provider_response_is_object'
  ) then
    alter table public.orders
      add constraint orders_provider_response_is_object
      check (jsonb_typeof(provider_response) = 'object');
  end if;
end
$$;

create unique index if not exists orders_provider_order_id_key
on public.orders (provider_order_id)
where provider_order_id is not null;

create or replace function public.apply_order_provider_status(
  p_order_id uuid,
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
  order_id uuid,
  order_no text,
  order_status text,
  payment_status text,
  payment_paid_at timestamptz,
  payment_expires_at timestamptz,
  already_processed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_next_payment_status text;
  v_next_order_status text;
  v_already_processed boolean := false;
begin
  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Pesanan tidak ditemukan';
  end if;

  v_next_payment_status := case lower(coalesce(p_provider_status, ''))
    when 'capture' then 'paid'
    when 'settlement' then 'paid'
    when 'pending' then 'unpaid'
    when 'deny' then 'failed'
    when 'failure' then 'failed'
    when 'cancel' then 'failed'
    when 'expire' then 'failed'
    when 'refund' then 'refunded'
    when 'partial_refund' then 'refunded'
    else v_order.payment_status
  end;

  v_next_order_status := case
    when v_next_payment_status = 'paid' and v_order.order_status = 'pending'
      then 'processing'
    when v_next_payment_status in ('failed', 'refunded') and v_order.order_status = 'pending'
      then 'cancelled'
    else v_order.order_status
  end;

  if v_order.payment_status = 'paid' then
    v_already_processed := true;
  end if;

  update public.orders
  set
    payment_status = v_next_payment_status,
    order_status = v_next_order_status,
    provider_status = coalesce(p_provider_status, provider_status),
    provider_transaction_id = coalesce(p_provider_transaction_id, provider_transaction_id),
    provider_payment_type = coalesce(p_provider_payment_type, provider_payment_type),
    provider_payment_code = coalesce(p_provider_payment_code, provider_payment_code),
    provider_va_number = coalesce(p_provider_va_number, provider_va_number),
    provider_bank = coalesce(p_provider_bank, provider_bank),
    provider_qr_url = coalesce(p_provider_qr_url, provider_qr_url),
    provider_response = coalesce(p_provider_response, '{}'::jsonb),
    payment_paid_at = case
      when v_order.payment_status <> 'paid' and v_next_payment_status = 'paid'
        then coalesce(p_paid_at, now())
      else public.orders.payment_paid_at
    end,
    payment_expires_at = coalesce(p_expires_at, public.orders.payment_expires_at)
  where id = v_order.id;

  return query
  select
    v_order.id,
    v_order.order_no,
    v_next_order_status,
    v_next_payment_status,
    case
      when v_order.payment_status <> 'paid' and v_next_payment_status = 'paid'
        then coalesce(p_paid_at, now())
      else v_order.payment_paid_at
    end,
    coalesce(p_expires_at, v_order.payment_expires_at),
    v_already_processed;
end;
$$;

grant execute on function public.apply_order_provider_status(
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
