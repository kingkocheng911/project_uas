alter table public.orders
  add column if not exists customer_name text,
  add column if not exists customer_phone text,
  add column if not exists delivery_label text,
  add column if not exists delivery_address text,
  add column if not exists courier_name text,
  add column if not exists courier_phone text;
update public.orders o
set
  customer_name = coalesce(nullif(o.customer_name, ''), p.full_name),
  customer_phone = coalesce(nullif(o.customer_phone, ''), p.phone)
from public.profiles p
where p.id = o.user_id
  and (
    o.customer_name is null or o.customer_name = ''
    or o.customer_phone is null or o.customer_phone = ''
  );
update public.orders o
set
  delivery_label = coalesce(nullif(o.delivery_label, ''), a.label),
  delivery_address = coalesce(nullif(o.delivery_address, ''), a.address)
from public.addresses a
where a.id = o.address_id
  and o.order_type = 'delivery'
  and (
    o.delivery_label is null or o.delivery_label = ''
    or o.delivery_address is null or o.delivery_address = ''
  );
