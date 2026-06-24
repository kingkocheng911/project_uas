create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  title text not null,
  description text,
  icon_name text not null default 'ticket',
  discount_type text not null
    check (discount_type in ('free_delivery', 'percentage', 'fixed_amount')),
  discount_value integer not null default 0,
  max_discount integer,
  minimum_spend integer not null default 0,
  quota_total integer,
  quota_used integer not null default 0,
  max_usage_per_user integer not null default 1,
  start_at timestamptz not null default now(),
  end_at timestamptz not null,
  is_active boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vouchers_code_not_blank check (btrim(code) <> ''),
  constraint vouchers_discount_value_non_negative check (discount_value >= 0),
  constraint vouchers_minimum_spend_non_negative check (minimum_spend >= 0),
  constraint vouchers_quota_valid check (quota_total is null or quota_total >= 0),
  constraint vouchers_quota_used_valid check (quota_used >= 0),
  constraint vouchers_usage_valid check (max_usage_per_user > 0),
  constraint vouchers_schedule_valid check (end_at > start_at)
);

create unique index if not exists vouchers_code_key
on public.vouchers (upper(code));

create table if not exists public.voucher_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  voucher_id uuid not null references public.vouchers (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  discount_amount integer not null default 0,
  redeemed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint voucher_redemptions_discount_non_negative check (discount_amount >= 0)
);

create index if not exists voucher_redemptions_user_id_idx
on public.voucher_redemptions (user_id);

create index if not exists voucher_redemptions_voucher_id_idx
on public.voucher_redemptions (voucher_id);

create unique index if not exists voucher_redemptions_order_voucher_key
on public.voucher_redemptions (order_id, voucher_id)
where order_id is not null;

create or replace function public.validate_voucher_redemption()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_voucher public.vouchers%rowtype;
  v_usage_count integer;
begin
  select *
  into v_voucher
  from public.vouchers
  where id = new.voucher_id
  for update;

  if not found then
    raise exception 'Voucher tidak ditemukan.';
  end if;

  if not v_voucher.is_active
    or v_voucher.start_at > now()
    or v_voucher.end_at < now()
  then
    raise exception 'Voucher sudah tidak aktif.';
  end if;

  if v_voucher.quota_total is not null
    and v_voucher.quota_used >= v_voucher.quota_total
  then
    raise exception 'Kuota voucher sudah habis.';
  end if;

  select count(*)
  into v_usage_count
  from public.voucher_redemptions
  where user_id = new.user_id
    and voucher_id = new.voucher_id;

  if v_usage_count >= v_voucher.max_usage_per_user then
    raise exception 'Voucher sudah pernah dipakai.';
  end if;

  return new;
end;
$$;

create or replace function public.increment_voucher_quota_used()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.vouchers
  set quota_used = quota_used + 1,
      updated_at = now()
  where id = new.voucher_id;

  return new;
end;
$$;

drop trigger if exists validate_voucher_redemption_before_insert
on public.voucher_redemptions;
create trigger validate_voucher_redemption_before_insert
before insert on public.voucher_redemptions
for each row execute procedure public.validate_voucher_redemption();

drop trigger if exists increment_voucher_quota_after_insert
on public.voucher_redemptions;
create trigger increment_voucher_quota_after_insert
after insert on public.voucher_redemptions
for each row execute procedure public.increment_voucher_quota_used();

drop trigger if exists set_vouchers_updated_at on public.vouchers;
create trigger set_vouchers_updated_at
before update on public.vouchers
for each row execute procedure public.set_updated_at();

alter table public.vouchers enable row level security;
alter table public.voucher_redemptions enable row level security;

drop policy if exists "users read active vouchers" on public.vouchers;
create policy "users read active vouchers"
on public.vouchers
for select
to authenticated, anon
using (
  is_active = true
);

drop policy if exists "superadmin manage vouchers" on public.vouchers;
create policy "superadmin manage vouchers"
on public.vouchers
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "users read own voucher redemptions" on public.voucher_redemptions;
create policy "users read own voucher redemptions"
on public.voucher_redemptions
for select
to authenticated
using (auth.uid() = user_id or public.is_superadmin());

drop policy if exists "users redeem own vouchers" on public.voucher_redemptions;
create policy "users redeem own vouchers"
on public.voucher_redemptions
for insert
to authenticated
with check (auth.uid() = user_id);

insert into public.vouchers (
  code,
  title,
  description,
  icon_name,
  discount_type,
  discount_value,
  max_discount,
  minimum_spend,
  quota_total,
  max_usage_per_user,
  start_at,
  end_at,
  is_active
)
select
  seed.code,
  seed.title,
  seed.description,
  seed.icon_name,
  seed.discount_type,
  seed.discount_value,
  seed.max_discount,
  seed.minimum_spend,
  seed.quota_total,
  seed.max_usage_per_user,
  now() - interval '1 day',
  now() + interval '180 days',
  true
from (
  values
    (
      'ONGKIRHEMAT',
      'Gratis Ongkir',
      'Potongan ongkir sampai Rp 8.000',
      'local_shipping',
      'free_delivery',
      8000,
      8000,
      50000,
      1000,
      1
    ),
    (
      'MEPU10',
      'Diskon Belanja 10%',
      'Maksimal potongan Rp 25.000',
      'percent',
      'percentage',
      10,
      25000,
      100000,
      1000,
      1
    ),
    (
      'ANGGOTA15',
      'Voucher Anggota',
      'Potongan langsung Rp 15.000',
      'premium',
      'fixed_amount',
      15000,
      null,
      75000,
      1000,
      1
    )
) as seed(
  code,
  title,
  description,
  icon_name,
  discount_type,
  discount_value,
  max_discount,
  minimum_spend,
  quota_total,
  max_usage_per_user
)
where not exists (
  select 1
  from public.vouchers v
  where upper(v.code) = upper(seed.code)
);
