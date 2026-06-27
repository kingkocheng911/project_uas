create table if not exists public.wallet_topups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  amount integer not null check (amount >= 10000),
  admin_fee integer not null default 1000 check (admin_fee >= 0),
  total_payment integer not null check (total_payment >= 0),
  payment_method text not null
    check (payment_method in ('virtual_account', 'qris')),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'cancelled', 'expired')),
  sandbox_provider text not null default 'kdmp_sandbox',
  sandbox_reference text not null unique,
  payment_instruction text,
  metadata jsonb not null default '{}'::jsonb,
  paid_at timestamptz,
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wallet_topups_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);
drop trigger if exists set_wallet_topups_updated_at on public.wallet_topups;
create trigger set_wallet_topups_updated_at
before update on public.wallet_topups
for each row execute procedure public.set_updated_at();
alter table public.wallet_topups enable row level security;
drop policy if exists "users read own wallet topups" on public.wallet_topups;
create policy "users read own wallet topups"
on public.wallet_topups
for select
to authenticated
using (auth.uid() = user_id or public.is_superadmin());
drop policy if exists "users create own wallet topups" on public.wallet_topups;
create policy "users create own wallet topups"
on public.wallet_topups
for insert
to authenticated
with check (auth.uid() = user_id);
drop policy if exists "users update own pending wallet topups" on public.wallet_topups;
create policy "users update own pending wallet topups"
on public.wallet_topups
for update
to authenticated
using (auth.uid() = user_id and status = 'pending')
with check (auth.uid() = user_id);
create or replace function public.create_wallet_topup(
  p_amount integer,
  p_payment_method text
)
returns table (
  topup_id uuid,
  amount integer,
  admin_fee integer,
  total_payment integer,
  payment_method text,
  status text,
  sandbox_reference text,
  payment_instruction text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_admin_fee integer := 1000;
  v_reference text;
  v_instruction text;
  v_topup public.wallet_topups%rowtype;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_amount is null or p_amount < 10000 then
    raise exception 'Minimal top up Rp 10.000';
  end if;

  if p_payment_method not in ('virtual_account', 'qris') then
    raise exception 'Metode pembayaran sandbox tidak valid';
  end if;

  v_reference := 'TOPUP-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
  v_instruction := case
    when p_payment_method = 'qris'
      then 'Scan QRIS sandbox lalu tekan tombol konfirmasi pembayaran di aplikasi.'
    else 'Transfer ke Virtual Account sandbox lalu tekan tombol konfirmasi pembayaran di aplikasi.'
  end;

  insert into public.wallet_topups (
    user_id,
    amount,
    admin_fee,
    total_payment,
    payment_method,
    sandbox_reference,
    payment_instruction,
    metadata
  )
  values (
    v_user_id,
    p_amount,
    v_admin_fee,
    p_amount + v_admin_fee,
    p_payment_method,
    v_reference,
    v_instruction,
    jsonb_build_object('mode', 'sandbox')
  )
  returning * into v_topup;

  return query
  select
    v_topup.id,
    v_topup.amount,
    v_topup.admin_fee,
    v_topup.total_payment,
    v_topup.payment_method,
    v_topup.status,
    v_topup.sandbox_reference,
    v_topup.payment_instruction,
    v_topup.expires_at;
end;
$$;
create or replace function public.confirm_wallet_topup(
  p_topup_id uuid
)
returns table (
  topup_id uuid,
  status text,
  wallet_balance integer,
  paid_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_topup public.wallet_topups%rowtype;
  v_wallet_balance integer;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into v_topup
  from public.wallet_topups
  where id = p_topup_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Transaksi top up tidak ditemukan';
  end if;

  if v_topup.status = 'paid' then
    select p.wallet_balance
    into v_wallet_balance
    from public.profiles p
    where p.id = v_user_id;

    return query
    select v_topup.id, v_topup.status, coalesce(v_wallet_balance, 0), v_topup.paid_at;
    return;
  end if;

  if v_topup.status <> 'pending' then
    raise exception 'Transaksi top up tidak dapat dikonfirmasi';
  end if;

  if v_topup.expires_at < now() then
    update public.wallet_topups
    set status = 'expired'
    where id = v_topup.id;
    raise exception 'Transaksi top up sandbox sudah kedaluwarsa';
  end if;

  update public.wallet_topups
  set
    status = 'paid',
    paid_at = now()
  where id = v_topup.id;

  update public.profiles
  set wallet_balance = wallet_balance + v_topup.amount
  where id = v_user_id
  returning profiles.wallet_balance into v_wallet_balance;

  return query
  select v_topup.id, 'paid'::text, coalesce(v_wallet_balance, 0), now();
end;
$$;
grant execute on function public.create_wallet_topup(integer, text) to authenticated;
grant execute on function public.confirm_wallet_topup(uuid) to authenticated;
