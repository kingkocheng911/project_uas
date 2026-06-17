delete from auth.users;

drop view if exists public.user_accounts;

drop trigger if exists on_auth_user_created on auth.users;

drop function if exists public.handle_new_user() cascade;
drop function if exists public.set_updated_at() cascade;

drop table if exists public.addresses cascade;
drop table if exists public.user_settings cascade;
drop table if exists public.profiles cascade;
