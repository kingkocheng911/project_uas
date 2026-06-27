create or replace view public.user_accounts as
select
  u.id,
  u.email,
  coalesce(nullif(p.full_name, ''), split_part(coalesce(u.email, ''), '@', 1), 'user') as full_name,
  coalesce(nullif(p.phone, ''), nullif(u.phone, ''), '-') as phone,
  coalesce(p.role, 'user') as role,
  coalesce(nullif(p.avatar_url, ''), '__initials__') as avatar_url,
  (u.email_confirmed_at is not null) as email_confirmed,
  u.last_sign_in_at,
  u.created_at
from auth.users u
left join public.profiles p on p.id = u.id;
insert into public.profiles (id, full_name, phone, avatar_url, role)
select
  u.id,
  case
    when u.email = 'admin@mepupoin.com' then 'Safitri Novitasari'
    when u.email = 'budi.santoso@email.com' then 'Budi Santoso'
    when u.email = 'rani.pratama@email.com' then 'Rani Pratama'
    else initcap(replace(split_part(coalesce(u.email, 'member@mepupoin.com'), '@', 1), '.', ' '))
  end,
  coalesce(
    nullif(u.phone, ''),
    case
      when u.email = 'admin@mepupoin.com' then '+62 811-2233-4455'
      when u.email = 'budi.santoso@email.com' then '+62 812-3456-7890'
      when u.email = 'rani.pratama@email.com' then '+62 813-7788-9900'
      else '+62 812-0000-0000'
    end
  ),
  '__initials__',
  case
    when u.email = 'admin@mepupoin.com' then 'superadmin'
    else 'user'
  end
from auth.users u
on conflict (id) do update
set
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role;
insert into public.user_settings (user_id, notifications)
select
  u.id,
  case
    when u.email = 'admin@mepupoin.com' then jsonb_build_object(
      'orders', true,
      'promotions', true,
      'payments', true,
      'membership', true,
      'security', true,
      'newsletter', true,
      'email', true,
      'sms', true,
      'push', true
    )
    else jsonb_build_object(
      'orders', true,
      'promotions', true,
      'payments', true,
      'membership', false,
      'security', true,
      'newsletter', false,
      'email', true,
      'sms', false,
      'push', true
    )
  end
from auth.users u
on conflict (user_id) do update
set notifications = excluded.notifications;
with candidate_addresses as (
  select
    u.id as user_id,
    coalesce(p.full_name, initcap(replace(split_part(coalesce(u.email, 'member@mepupoin.com'), '@', 1), '.', ' '))) as recipient_name,
    coalesce(nullif(p.phone, ''), nullif(u.phone, ''), '+62 812-0000-0000') as phone,
    row_number() over (order by u.created_at, u.email) as rn
  from auth.users u
  left join public.profiles p on p.id = u.id
)
insert into public.addresses (
  user_id,
  label,
  recipient_name,
  phone,
  address,
  icon,
  is_primary
)
select
  c.user_id,
  a.label,
  c.recipient_name,
  c.phone,
  a.address,
  a.icon,
  true
from candidate_addresses c
join (
  values
    (1, 'Rumah', 'Jl. Melati No. 12, Antapani, Bandung, Jawa Barat 40291', 'home_outlined'),
    (2, 'Kantor', 'Jl. Asia Afrika No. 88, Sumur Bandung, Bandung, Jawa Barat 40111', 'business_outlined'),
    (3, 'Kontrakan', 'Jl. Cendana No. 7, Jatinangor, Sumedang, Jawa Barat 45363', 'location_on_outlined'),
    (4, 'Rumah Orang Tua', 'Jl. Ahmad Yani No. 45, Subang, Jawa Barat 41211', 'people_outline_rounded')
) as a(rn, label, address, icon)
  on ((c.rn - 1) % 4) + 1 = a.rn
where not exists (
  select 1
  from public.addresses existing
  where existing.user_id = c.user_id
);
