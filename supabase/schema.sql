create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  avatar_url text not null default '__initials__',
  role text not null default 'user' check (role in ('user', 'admin', 'superadmin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  label text not null,
  recipient_name text not null,
  phone text not null,
  address text not null,
  icon text not null default 'location_on_outlined',
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  notifications jsonb not null default jsonb_build_object(
    'orders', true,
    'promotions', true,
    'payments', true,
    'membership', false,
    'security', true,
    'newsletter', false,
    'email', true,
    'sms', false,
    'push', true
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_settings_notifications_is_object
    check (jsonb_typeof(notifications) = 'object')
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  label text not null unique,
  icon_name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  name text not null,
  price integer not null,
  original_price integer not null,
  stock integer not null default 0,
  claimed_percent integer not null default 0,
  reward_points integer not null default 0,
  badge text not null default '',
  description text not null,
  icon_name text not null,
  tone_hex text not null,
  image_url text,
  category_labels text[] not null default '{}',
  highlights text[] not null default '{}',
  related_ids text[] not null default '{}',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute procedure public.set_updated_at();

drop trigger if exists set_addresses_updated_at on public.addresses;
create trigger set_addresses_updated_at
before update on public.addresses
for each row execute procedure public.set_updated_at();

drop trigger if exists set_user_settings_updated_at on public.user_settings;
create trigger set_user_settings_updated_at
before update on public.user_settings
for each row execute procedure public.set_updated_at();

drop trigger if exists set_products_updated_at on public.products;
create trigger set_products_updated_at
before update on public.products
for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.addresses enable row level security;
alter table public.user_settings enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;

drop policy if exists "users can read own profile" on public.profiles;
create policy "users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users can insert own profile" on public.profiles;
create policy "users can insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "users can update own profile" on public.profiles;
create policy "users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "users can manage own addresses" on public.addresses;
create policy "users can manage own addresses"
on public.addresses
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own settings" on public.user_settings;
create policy "users can manage own settings"
on public.user_settings
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "anyone can read categories" on public.categories;
create policy "anyone can read categories"
on public.categories
for select
to authenticated, anon
using (true);

drop policy if exists "anyone can read products" on public.products;
create policy "anyone can read products"
on public.products
for select
to authenticated, anon
using (true);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, avatar_url, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'phone',
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '__initials__'),
    case lower(coalesce(new.raw_user_meta_data ->> 'role', 'user'))
      when 'superadmin' then 'superadmin'
      when 'admin' then 'admin'
      else 'user'
    end
  )
  on conflict (id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
