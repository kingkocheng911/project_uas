create extension if not exists "pgcrypto";
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
alter table public.profiles
add column if not exists role text not null default 'user';
update public.profiles
set role = case lower(coalesce(role_label, ''))
  when 'superadmin' then 'superadmin'
  when 'admin' then 'admin'
  when 'branch admin' then 'admin'
  else 'user'
end;
alter table public.profiles
drop constraint if exists profiles_role_check;
alter table public.profiles
add constraint profiles_role_check
check (role in ('user', 'admin', 'superadmin'));
insert into public.user_settings (user_id, notifications, created_at, updated_at)
select
  user_id,
  jsonb_build_object(
    'orders', orders_enabled,
    'promotions', promotions_enabled,
    'payments', payments_enabled,
    'membership', membership_enabled,
    'security', security_enabled,
    'newsletter', newsletter_enabled,
    'email', email_enabled,
    'sms', sms_enabled,
    'push', push_enabled
  ),
  created_at,
  updated_at
from public.notification_settings
on conflict (user_id) do update
set
  notifications = excluded.notifications,
  updated_at = excluded.updated_at;
drop trigger if exists set_user_settings_updated_at on public.user_settings;
create trigger set_user_settings_updated_at
before update on public.user_settings
for each row execute procedure public.set_updated_at();
alter table public.user_settings enable row level security;
drop policy if exists "users can manage own settings" on public.user_settings;
create policy "users can manage own settings"
on public.user_settings
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
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
alter table public.profiles
drop column if exists role_label;
drop table if exists public.notification_settings cascade;
drop table if exists public.payment_methods cascade;
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.products cascade;
