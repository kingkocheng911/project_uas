create extension if not exists "pgcrypto";

create or replace function public.is_superadmin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('superadmin', 'super_admin')
  );
$$;

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  phone text,
  email text,
  address text not null,
  province text,
  city text,
  district text,
  postal_code text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  is_active boolean not null default true,
  opened_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.branch_admins (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  admin_role text not null default 'branch_admin'
    check (admin_role in ('branch_admin', 'branch_manager', 'cashier')),
  is_primary boolean not null default false,
  is_active boolean not null default true,
  assigned_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists branch_admins_branch_user_active_idx
on public.branch_admins (branch_id, user_id)
where is_active = true;

create or replace function public.is_branch_admin(target_branch_id uuid)
returns boolean
language sql
stable
as $$
  select
    public.is_superadmin()
    or exists (
      select 1
      from public.branch_admins
      where user_id = auth.uid()
        and branch_id = target_branch_id
        and is_active = true
    );
$$;

alter table public.profiles
  add column if not exists default_branch_id uuid references public.branches (id) on delete set null,
  add column if not exists member_code text,
  add column if not exists role_type text,
  add column if not exists is_active boolean not null default true;

update public.profiles
set
  role_type = case
    when coalesce(role_type, '') <> '' then role_type
    when role in ('superadmin', 'super_admin') then 'super_admin'
    else 'customer'
  end
where role_type is null;

create unique index if not exists profiles_member_code_key
on public.profiles (member_code)
where member_code is not null;

alter table public.categories
  add column if not exists parent_id uuid references public.categories (id) on delete set null,
  add column if not exists slug text,
  add column if not exists updated_at timestamptz not null default now();

update public.categories
set slug = lower(regexp_replace(label, '[^a-zA-Z0-9]+', '-', 'g'))
where slug is null;

create unique index if not exists categories_slug_key on public.categories (slug);

alter table public.products
  add column if not exists sku text,
  add column if not exists barcode text,
  add column if not exists slug text,
  add column if not exists category_id uuid references public.categories (id) on delete set null,
  add column if not exists unit text not null default 'pcs',
  add column if not exists brand text,
  add column if not exists weight_grams numeric(10, 2);

update public.products
set
  sku = coalesce(sku, id),
  slug = coalesce(slug, lower(regexp_replace(name || '-' || id, '[^a-zA-Z0-9]+', '-', 'g')))
where sku is null or slug is null;

create unique index if not exists products_sku_key on public.products (sku);
create unique index if not exists products_slug_key on public.products (slug);

create table if not exists public.branch_products (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  product_id text not null references public.products (id) on delete cascade,
  selling_price integer not null default 0,
  original_price integer not null default 0,
  cost_price integer,
  stock_on_hand integer not null default 0,
  stock_reserved integer not null default 0,
  min_stock_alert integer not null default 0,
  is_active boolean not null default true,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branch_products_stock_non_negative
    check (stock_on_hand >= 0 and stock_reserved >= 0 and min_stock_alert >= 0)
);

create unique index if not exists branch_products_branch_product_key
on public.branch_products (branch_id, product_id);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid references public.branches (id) on delete cascade,
  title text not null,
  description text,
  promo_type text not null
    check (promo_type in ('percentage', 'fixed_amount', 'bundle', 'buy_x_get_y')),
  promo_scope text not null default 'all_products'
    check (promo_scope in ('all_products', 'category', 'product')),
  category_id uuid references public.categories (id) on delete set null,
  product_id text references public.products (id) on delete set null,
  discount_value integer not null default 0,
  min_purchase integer,
  max_discount integer,
  quota_total integer,
  quota_used integer not null default 0,
  start_at timestamptz not null,
  end_at timestamptz not null,
  is_active boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotions_schedule_valid check (end_at > start_at)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  branch_id uuid references public.branches (id) on delete set null,
  type text not null
    check (type in ('order', 'promo', 'system', 'stock', 'admin')),
  title text not null,
  message text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_data_is_object check (jsonb_typeof(data) = 'object')
);

create table if not exists public.notification_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  orders_enabled boolean not null default true,
  promotions_enabled boolean not null default true,
  payments_enabled boolean not null default true,
  membership_enabled boolean not null default false,
  security_enabled boolean not null default true,
  newsletter_enabled boolean not null default false,
  email_enabled boolean not null default true,
  sms_enabled boolean not null default false,
  push_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  code text,
  name text,
  type text,
  provider_name text,
  account_name text,
  account_ref text,
  badge_label text,
  is_primary boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payment_methods
  add column if not exists user_id uuid references auth.users (id) on delete cascade,
  add column if not exists code text,
  add column if not exists name text,
  add column if not exists type text,
  add column if not exists provider_name text,
  add column if not exists account_name text,
  add column if not exists account_ref text,
  add column if not exists badge_label text,
  add column if not exists is_primary boolean not null default false,
  add column if not exists is_active boolean not null default true,
  add column if not exists sort_order integer not null default 0,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'payment_methods'
      and column_name = 'user_id'
      and is_nullable = 'NO'
  ) then
    alter table public.payment_methods
      alter column user_id drop not null;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'payment_methods'
      and column_name = 'method_type'
  ) then
    execute $payment_methods_backfill$
      update public.payment_methods
      set
        type = coalesce(
          type,
          case method_type
            when 'bank' then 'bank_transfer'
            when 'ewallet' then 'ewallet'
            else 'cash'
          end
        ),
        name = coalesce(name, provider_name, account_name, 'Metode Pembayaran'),
        code = coalesce(code, 'legacy-' || id::text)
      where type is null or name is null or code is null
    $payment_methods_backfill$;
  else
    update public.payment_methods
    set
      type = coalesce(type, 'cash'),
      name = coalesce(name, provider_name, account_name, 'Metode Pembayaran'),
      code = coalesce(code, 'legacy-' || id::text)
    where type is null or name is null or code is null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'payment_methods_type_check'
  ) then
    alter table public.payment_methods
      add constraint payment_methods_type_check
      check (type in ('cash', 'bank_transfer', 'ewallet', 'qris', 'cod'));
  end if;
end $$;

create unique index if not exists payment_methods_code_key
on public.payment_methods (code)
where code is not null;

do $$
begin
  if to_regclass('public.user_settings') is not null then
    execute $notification_settings_migration$
      insert into public.notification_settings (
        user_id,
        orders_enabled,
        promotions_enabled,
        payments_enabled,
        membership_enabled,
        security_enabled,
        newsletter_enabled,
        email_enabled,
        sms_enabled,
        push_enabled
      )
      select
        us.user_id,
        coalesce((us.notifications ->> 'orders')::boolean, true),
        coalesce((us.notifications ->> 'promotions')::boolean, true),
        coalesce((us.notifications ->> 'payments')::boolean, true),
        coalesce((us.notifications ->> 'membership')::boolean, false),
        coalesce((us.notifications ->> 'security')::boolean, true),
        coalesce((us.notifications ->> 'newsletter')::boolean, false),
        coalesce((us.notifications ->> 'email')::boolean, true),
        coalesce((us.notifications ->> 'sms')::boolean, false),
        coalesce((us.notifications ->> 'push')::boolean, true)
      from public.user_settings us
      on conflict (user_id) do nothing
    $notification_settings_migration$;
  end if;
end $$;

insert into public.payment_methods (code, name, type, provider_name, sort_order)
select seed.code, seed.name, seed.type, seed.provider_name, seed.sort_order
from (
  values
    ('cash', 'Tunai', 'cash', 'Kasir Cabang', 1),
    ('transfer_bca', 'Transfer BCA', 'bank_transfer', 'BCA', 2),
    ('transfer_bri', 'Transfer BRI', 'bank_transfer', 'BRI', 3),
    ('gopay', 'GoPay', 'ewallet', 'GoPay', 4),
    ('qris', 'QRIS', 'qris', 'QRIS Nasional', 5),
    ('cod', 'Bayar di Tempat', 'cod', 'Cabang KDMP', 6)
) as seed(code, name, type, provider_name, sort_order)
where not exists (
  select 1
  from public.payment_methods pm
  where pm.code = seed.code
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_no text unique,
  user_id uuid not null references auth.users (id) on delete cascade,
  branch_id uuid references public.branches (id) on delete set null,
  address_id uuid references public.addresses (id) on delete set null,
  payment_method_id uuid references public.payment_methods (id) on delete set null,
  promo_id uuid references public.promotions (id) on delete set null,
  order_type text not null default 'delivery'
    check (order_type in ('delivery', 'pickup')),
  order_status text not null default 'pending'
    check (order_status in (
      'pending',
      'confirmed',
      'processing',
      'ready_pickup',
      'out_for_delivery',
      'completed',
      'cancelled'
    )),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'failed', 'refunded')),
  subtotal integer not null default 0,
  discount_total integer not null default 0,
  delivery_fee integer not null default 0,
  grand_total integer not null default 0,
  notes text,
  placed_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders
  add column if not exists order_no text,
  add column if not exists branch_id uuid references public.branches (id) on delete set null,
  add column if not exists address_id uuid references public.addresses (id) on delete set null,
  add column if not exists payment_method_id uuid references public.payment_methods (id) on delete set null,
  add column if not exists promo_id uuid references public.promotions (id) on delete set null,
  add column if not exists order_type text not null default 'delivery',
  add column if not exists order_status text not null default 'pending',
  add column if not exists payment_status text not null default 'unpaid',
  add column if not exists subtotal integer not null default 0,
  add column if not exists discount_total integer not null default 0,
  add column if not exists delivery_fee integer not null default 0,
  add column if not exists grand_total integer not null default 0,
  add column if not exists notes text,
  add column if not exists placed_at timestamptz not null default now(),
  add column if not exists completed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_order_type_check'
  ) then
    alter table public.orders
      add constraint orders_order_type_check
      check (order_type in ('delivery', 'pickup'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_order_status_check'
  ) then
    alter table public.orders
      add constraint orders_order_status_check
      check (order_status in (
        'pending',
        'confirmed',
        'processing',
        'ready_pickup',
        'out_for_delivery',
        'completed',
        'cancelled'
      ));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_payment_status_check'
  ) then
    alter table public.orders
      add constraint orders_payment_status_check
      check (payment_status in ('unpaid', 'paid', 'failed', 'refunded'));
  end if;
end $$;

update public.orders
set
  placed_at = coalesce(placed_at, created_at, now())
where placed_at is null;

do $$
declare
  has_status boolean;
  has_total boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'status'
  ) into has_status;

  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'total'
  ) into has_total;

  if has_status then
    execute $orders_status_backfill$
      update public.orders
      set order_status = coalesce(nullif(order_status, ''), status, 'pending')
      where order_status is null or order_status = ''
    $orders_status_backfill$;
  end if;

  if has_total then
    execute $orders_total_backfill$
      update public.orders
      set
        grand_total = case when grand_total = 0 then coalesce(total, 0) else grand_total end,
        subtotal = case when subtotal = 0 then coalesce(total, 0) else subtotal end
    $orders_total_backfill$;
  end if;
end $$;

create unique index if not exists orders_order_no_key
on public.orders (order_no)
where order_no is not null;

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  branch_product_id uuid references public.branch_products (id) on delete set null,
  product_id text references public.products (id) on delete set null,
  product_name text not null,
  sku text,
  qty integer not null default 1,
  unit_price integer not null default 0,
  discount_amount integer not null default 0,
  subtotal integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.order_items
  add column if not exists branch_product_id uuid references public.branch_products (id) on delete set null,
  add column if not exists sku text,
  add column if not exists qty integer not null default 1,
  add column if not exists discount_amount integer not null default 0,
  add column if not exists subtotal integer not null default 0;

update public.order_items
set
  qty = coalesce(qty, 1)
where qty is null;

do $$
declare
  has_quantity boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'order_items'
      and column_name = 'quantity'
  ) into has_quantity;

  if has_quantity then
    execute $order_items_quantity_backfill$
      update public.order_items
      set
        qty = coalesce(qty, quantity, 1),
        subtotal = case
          when subtotal = 0 then coalesce(quantity, qty, 1) * coalesce(unit_price, 0)
          else subtotal
        end
    $order_items_quantity_backfill$;
  else
    update public.order_items
    set subtotal = case
      when subtotal = 0 then coalesce(qty, 1) * coalesce(unit_price, 0)
      else subtotal
    end;
  end if;
end $$;

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  branch_product_id uuid not null references public.branch_products (id) on delete cascade,
  branch_id uuid not null references public.branches (id) on delete cascade,
  product_id text not null references public.products (id) on delete cascade,
  movement_type text not null
    check (movement_type in (
      'opening',
      'purchase',
      'sale',
      'adjustment_in',
      'adjustment_out',
      'return',
      'cancel_release'
    )),
  qty_change integer not null,
  qty_before integer not null default 0,
  qty_after integer not null default 0,
  reference_type text not null default 'manual'
    check (reference_type in ('order', 'manual', 'restock', 'system')),
  reference_id uuid,
  notes text,
  performed_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.branch_performance (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  period_date date not null,
  period_type text not null check (period_type in ('daily', 'monthly')),
  total_orders integer not null default 0,
  completed_orders integer not null default 0,
  gross_revenue integer not null default 0,
  net_revenue integer not null default 0,
  items_sold integer not null default 0,
  active_customers integer not null default 0,
  stockout_count integer not null default 0,
  cancelled_orders integer not null default 0,
  avg_order_value numeric(12, 2) not null default 0,
  performance_score numeric(8, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists branch_performance_period_key
on public.branch_performance (branch_id, period_date, period_type);

alter table public.addresses
  add column if not exists province text,
  add column if not exists city text,
  add column if not exists district text,
  add column if not exists postal_code text,
  add column if not exists latitude numeric(10, 7),
  add column if not exists longitude numeric(10, 7),
  add column if not exists notes text;

create or replace function public.generate_order_no()
returns trigger
language plpgsql
as $$
begin
  if new.order_no is null or new.order_no = '' then
    new.order_no := 'KDMP-' || to_char(coalesce(new.placed_at, now()), 'YYYYMMDD') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
  end if;
  return new;
end;
$$;

drop trigger if exists set_branches_updated_at on public.branches;
create trigger set_branches_updated_at
before update on public.branches
for each row execute procedure public.set_updated_at();

drop trigger if exists set_branch_admins_updated_at on public.branch_admins;
create trigger set_branch_admins_updated_at
before update on public.branch_admins
for each row execute procedure public.set_updated_at();

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
before update on public.categories
for each row execute procedure public.set_updated_at();

drop trigger if exists set_branch_products_updated_at on public.branch_products;
create trigger set_branch_products_updated_at
before update on public.branch_products
for each row execute procedure public.set_updated_at();

drop trigger if exists set_promotions_updated_at on public.promotions;
create trigger set_promotions_updated_at
before update on public.promotions
for each row execute procedure public.set_updated_at();

drop trigger if exists set_notification_settings_updated_at on public.notification_settings;
create trigger set_notification_settings_updated_at
before update on public.notification_settings
for each row execute procedure public.set_updated_at();

drop trigger if exists set_payment_methods_updated_at on public.payment_methods;
create trigger set_payment_methods_updated_at
before update on public.payment_methods
for each row execute procedure public.set_updated_at();

drop trigger if exists set_orders_updated_at on public.orders;
create trigger set_orders_updated_at
before update on public.orders
for each row execute procedure public.set_updated_at();

drop trigger if exists set_branch_performance_updated_at on public.branch_performance;
create trigger set_branch_performance_updated_at
before update on public.branch_performance
for each row execute procedure public.set_updated_at();

drop trigger if exists set_order_no_before_insert on public.orders;
create trigger set_order_no_before_insert
before insert on public.orders
for each row execute procedure public.generate_order_no();

alter table public.branches enable row level security;
alter table public.branch_admins enable row level security;
alter table public.branch_products enable row level security;
alter table public.promotions enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_settings enable row level security;
alter table public.payment_methods enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.stock_movements enable row level security;
alter table public.branch_performance enable row level security;

drop policy if exists "superadmin can read all profiles" on public.profiles;
create policy "superadmin can read all profiles"
on public.profiles
for select
to authenticated
using (public.is_superadmin());

drop policy if exists "superadmin can update all profiles" on public.profiles;
create policy "superadmin can update all profiles"
on public.profiles
for update
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "superadmin manage categories" on public.categories;
create policy "superadmin manage categories"
on public.categories
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "superadmin manage products" on public.products;
create policy "superadmin manage products"
on public.products
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "authenticated can read active branches" on public.branches;
create policy "authenticated can read active branches"
on public.branches
for select
to authenticated, anon
using (is_active = true or public.is_superadmin());

drop policy if exists "superadmin manage branches" on public.branches;
create policy "superadmin manage branches"
on public.branches
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "users can read own branch assignments" on public.branch_admins;
create policy "users can read own branch assignments"
on public.branch_admins
for select
to authenticated
using (auth.uid() = user_id or public.is_superadmin());

drop policy if exists "superadmin manage branch admins" on public.branch_admins;
create policy "superadmin manage branch admins"
on public.branch_admins
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "anyone can read branch products" on public.branch_products;
create policy "anyone can read branch products"
on public.branch_products
for select
to authenticated, anon
using (
  is_active = true
  and exists (
    select 1
    from public.branches b
    where b.id = branch_products.branch_id
      and b.is_active = true
  )
);

drop policy if exists "branch admins manage own branch products" on public.branch_products;
create policy "branch admins manage own branch products"
on public.branch_products
for all
to authenticated
using (public.is_branch_admin(branch_id))
with check (public.is_branch_admin(branch_id));

drop policy if exists "anyone can read active promotions" on public.promotions;
create policy "anyone can read active promotions"
on public.promotions
for select
to authenticated, anon
using (is_active = true and start_at <= now() and end_at >= now());

drop policy if exists "branch admins manage promotions" on public.promotions;
create policy "branch admins manage promotions"
on public.promotions
for all
to authenticated
using (
  public.is_superadmin()
  or (branch_id is not null and public.is_branch_admin(branch_id))
)
with check (
  public.is_superadmin()
  or (branch_id is not null and public.is_branch_admin(branch_id))
);

drop policy if exists "users manage own notification settings" on public.notification_settings;
create policy "users manage own notification settings"
on public.notification_settings
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users read own notifications" on public.notifications;
create policy "users read own notifications"
on public.notifications
for select
to authenticated
using (auth.uid() = user_id or public.is_superadmin());

drop policy if exists "system inserts notifications" on public.notifications;
create policy "system inserts notifications"
on public.notifications
for insert
to authenticated
with check (auth.uid() = user_id or public.is_superadmin());

drop policy if exists "users read active payment methods" on public.payment_methods;
create policy "users read active payment methods"
on public.payment_methods
for select
to authenticated, anon
using (is_active = true or public.is_superadmin());

drop policy if exists "superadmin manage payment methods" on public.payment_methods;
create policy "superadmin manage payment methods"
on public.payment_methods
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

drop policy if exists "users create own orders" on public.orders;
create policy "users create own orders"
on public.orders
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users read own orders and branch admins read assigned branch orders" on public.orders;
create policy "users read own orders and branch admins read assigned branch orders"
on public.orders
for select
to authenticated
using (
  auth.uid() = user_id
  or (branch_id is not null and public.is_branch_admin(branch_id))
);

drop policy if exists "users update own pending orders and branch admins update assigned branch orders" on public.orders;
create policy "users update own pending orders and branch admins update assigned branch orders"
on public.orders
for update
to authenticated
using (
  (auth.uid() = user_id and order_status = 'pending')
  or (branch_id is not null and public.is_branch_admin(branch_id))
)
with check (
  (auth.uid() = user_id and order_status = 'pending')
  or (branch_id is not null and public.is_branch_admin(branch_id))
);

drop policy if exists "users read related order items" on public.order_items;
create policy "users read related order items"
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_items.order_id
      and (
        o.user_id = auth.uid()
        or (o.branch_id is not null and public.is_branch_admin(o.branch_id))
      )
  )
);

drop policy if exists "users create related order items for own orders" on public.order_items;
create policy "users create related order items for own orders"
on public.order_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.orders o
    where o.id = order_items.order_id
      and o.user_id = auth.uid()
  )
);

drop policy if exists "branch admins read stock movements" on public.stock_movements;
create policy "branch admins read stock movements"
on public.stock_movements
for select
to authenticated
using (public.is_branch_admin(branch_id));

drop policy if exists "branch admins insert stock movements" on public.stock_movements;
create policy "branch admins insert stock movements"
on public.stock_movements
for insert
to authenticated
with check (public.is_branch_admin(branch_id));

drop policy if exists "branch admins read branch performance" on public.branch_performance;
create policy "branch admins read branch performance"
on public.branch_performance
for select
to authenticated
using (public.is_branch_admin(branch_id));

drop policy if exists "superadmin manage branch performance" on public.branch_performance;
create policy "superadmin manage branch performance"
on public.branch_performance
for all
to authenticated
using (public.is_superadmin())
with check (public.is_superadmin());

insert into storage.buckets (id, name, public)
select 'avatars', 'avatars', false
where not exists (
  select 1 from storage.buckets where id = 'avatars'
);

insert into storage.buckets (id, name, public)
select 'product-images', 'product-images', true
where not exists (
  select 1 from storage.buckets where id = 'product-images'
);

insert into storage.buckets (id, name, public)
select 'branch-assets', 'branch-assets', false
where not exists (
  select 1 from storage.buckets where id = 'branch-assets'
);

insert into storage.buckets (id, name, public)
select 'promotion-banners', 'promotion-banners', true
where not exists (
  select 1 from storage.buckets where id = 'promotion-banners'
);

drop policy if exists "users manage own avatar objects" on storage.objects;
create policy "users manage own avatar objects"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "public read product images" on storage.objects;
create policy "public read product images"
on storage.objects
for select
to authenticated, anon
using (bucket_id = 'product-images');

drop policy if exists "public read promotion banners" on storage.objects;
create policy "public read promotion banners"
on storage.objects
for select
to authenticated, anon
using (bucket_id = 'promotion-banners');

drop policy if exists "superadmin manage product image objects" on storage.objects;
create policy "superadmin manage product image objects"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'product-images'
  and public.is_superadmin()
)
with check (
  bucket_id = 'product-images'
  and public.is_superadmin()
);

drop policy if exists "superadmin manage branch asset objects" on storage.objects;
create policy "superadmin manage branch asset objects"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'branch-assets'
  and public.is_superadmin()
)
with check (
  bucket_id = 'branch-assets'
  and public.is_superadmin()
);

drop policy if exists "superadmin manage promotion banner objects" on storage.objects;
create policy "superadmin manage promotion banner objects"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'promotion-banners'
  and public.is_superadmin()
)
with check (
  bucket_id = 'promotion-banners'
  and public.is_superadmin()
);
