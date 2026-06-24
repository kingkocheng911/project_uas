create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, avatar_url, role, role_type, is_active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'phone',
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '__initials__'),
    case lower(coalesce(new.raw_user_meta_data ->> 'role', 'user'))
      when 'superadmin' then 'superadmin'
      when 'admin' then 'admin'
      else 'user'
    end,
    case lower(coalesce(new.raw_user_meta_data ->> 'role_type', new.raw_user_meta_data ->> 'role', 'customer'))
      when 'super_admin' then 'super_admin'
      when 'superadmin' then 'super_admin'
      when 'admin' then 'admin'
      when 'user' then 'customer'
      else 'customer'
    end,
    true
  )
  on conflict (id) do update
  set full_name = excluded.full_name,
      phone = excluded.phone,
      avatar_url = excluded.avatar_url,
      role = excluded.role,
      role_type = excluded.role_type,
      is_active = true,
      updated_at = now();

  insert into public.notification_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();