create table if not exists public.reward_rules (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  earn_points integer not null default 1 check (earn_points > 0),
  earn_amount_spent integer not null default 10000 check (earn_amount_spent > 0),
  redeem_points integer not null default 1 check (redeem_points > 0),
  redeem_amount integer not null default 100 check (redeem_amount > 0),
  min_redeem_points integer not null default 10 check (min_redeem_points >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reward_accounts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  current_balance integer not null default 0 check (current_balance >= 0),
  lifetime_earned integer not null default 0 check (lifetime_earned >= 0),
  lifetime_redeemed integer not null default 0 check (lifetime_redeemed >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reward_transactions (
  id uuid primary key default gen_random_uuid(),
  account_user_id uuid not null references public.reward_accounts (user_id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  transaction_type text not null
    check (transaction_type in ('earn', 'redeem', 'adjustment', 'expired')),
  points_delta integer not null,
  balance_before integer not null,
  balance_after integer not null,
  rupiah_value integer not null default 0,
  description text,
  reference_type text not null default 'system'
    check (reference_type in ('order', 'manual', 'expiry', 'system')),
  reference_id uuid,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists reward_transactions_account_created_at_idx
on public.reward_transactions (account_user_id, created_at desc);

alter table public.orders
  add column if not exists service_fee integer not null default 0,
  add column if not exists reward_points_redeemed integer not null default 0,
  add column if not exists reward_discount_total integer not null default 0,
  add column if not exists reward_points_earned integer not null default 0,
  add column if not exists reward_processed_at timestamptz;

drop trigger if exists set_reward_rules_updated_at on public.reward_rules;
create trigger set_reward_rules_updated_at
before update on public.reward_rules
for each row execute procedure public.set_updated_at();

drop trigger if exists set_reward_accounts_updated_at on public.reward_accounts;
create trigger set_reward_accounts_updated_at
before update on public.reward_accounts
for each row execute procedure public.set_updated_at();

insert into public.reward_rules (
  code,
  name,
  description,
  earn_points,
  earn_amount_spent,
  redeem_points,
  redeem_amount,
  min_redeem_points,
  is_active
)
values (
  'default_loyalty',
  'Aturan Default Mepu Point',
  'Belanja Rp10.000 mendapatkan 1 Mepu Point. 1 Mepu Point dapat ditukar menjadi potongan Rp100.',
  1,
  10000,
  1,
  100,
  10,
  true
)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  earn_points = excluded.earn_points,
  earn_amount_spent = excluded.earn_amount_spent,
  redeem_points = excluded.redeem_points,
  redeem_amount = excluded.redeem_amount,
  min_redeem_points = excluded.min_redeem_points,
  is_active = true,
  updated_at = now();

insert into public.reward_accounts (user_id)
select p.id
from public.profiles p
where not exists (
  select 1
  from public.reward_accounts ra
  where ra.user_id = p.id
);

create or replace function public._ensure_reward_account(
  p_user_id uuid
)
returns public.reward_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account public.reward_accounts%rowtype;
begin
  insert into public.reward_accounts (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select *
  into v_account
  from public.reward_accounts
  where user_id = p_user_id
  limit 1
  for update;

  return v_account;
end;
$$;

create or replace function public._active_reward_rule()
returns public.reward_rules
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rule public.reward_rules%rowtype;
begin
  select *
  into v_rule
  from public.reward_rules
  where is_active = true
  order by updated_at desc, created_at desc
  limit 1;

  if v_rule.id is null then
    raise exception 'Aturan Mepu Point belum aktif.';
  end if;

  return v_rule;
end;
$$;

create or replace function public.customer_get_reward_summary()
returns table(
  current_balance integer,
  lifetime_earned integer,
  lifetime_redeemed integer,
  earn_points integer,
  earn_amount_spent integer,
  redeem_points integer,
  redeem_amount integer,
  min_redeem_points integer,
  rule_name text,
  rule_description text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_account public.reward_accounts%rowtype;
  v_rule public.reward_rules%rowtype;
begin
  if v_user_id is null then
    raise exception 'User belum login.';
  end if;

  v_account := public._ensure_reward_account(v_user_id);
  v_rule := public._active_reward_rule();

  current_balance := coalesce(v_account.current_balance, 0);
  lifetime_earned := coalesce(v_account.lifetime_earned, 0);
  lifetime_redeemed := coalesce(v_account.lifetime_redeemed, 0);
  earn_points := v_rule.earn_points;
  earn_amount_spent := v_rule.earn_amount_spent;
  redeem_points := v_rule.redeem_points;
  redeem_amount := v_rule.redeem_amount;
  min_redeem_points := v_rule.min_redeem_points;
  rule_name := v_rule.name;
  rule_description := coalesce(v_rule.description, '');

  return next;
end;
$$;

create or replace function public.customer_preview_reward_redeem(
  p_subtotal integer,
  p_delivery_fee integer default 0,
  p_service_fee integer default 0,
  p_requested_points integer default null
)
returns table(
  available_balance integer,
  requested_points integer,
  applied_points integer,
  discount_amount integer,
  amount_before_discount integer,
  amount_after_discount integer,
  min_redeem_points integer,
  redeem_points integer,
  redeem_amount integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_account public.reward_accounts%rowtype;
  v_rule public.reward_rules%rowtype;
  v_before integer := greatest(coalesce(p_subtotal, 0), 0)
    + greatest(coalesce(p_delivery_fee, 0), 0)
    + greatest(coalesce(p_service_fee, 0), 0);
  v_requested integer := greatest(coalesce(p_requested_points, 0), 0);
  v_max_points_by_total integer;
  v_applied_points integer := 0;
begin
  if v_user_id is null then
    raise exception 'User belum login.';
  end if;

  v_account := public._ensure_reward_account(v_user_id);
  v_rule := public._active_reward_rule();

  if v_before <= 0 then
    available_balance := coalesce(v_account.current_balance, 0);
    requested_points := v_requested;
    applied_points := 0;
    discount_amount := 0;
    amount_before_discount := 0;
    amount_after_discount := 0;
    min_redeem_points := v_rule.min_redeem_points;
    redeem_points := v_rule.redeem_points;
    redeem_amount := v_rule.redeem_amount;
    return next;
  end if;

  v_max_points_by_total := floor(
    v_before::numeric * v_rule.redeem_points::numeric / v_rule.redeem_amount::numeric
  )::integer;

  if v_requested = 0 then
    v_requested := least(coalesce(v_account.current_balance, 0), v_max_points_by_total);
  end if;

  v_applied_points := least(
    v_requested,
    coalesce(v_account.current_balance, 0),
    v_max_points_by_total
  );

  if v_applied_points < v_rule.min_redeem_points then
    v_applied_points := 0;
  end if;

  available_balance := coalesce(v_account.current_balance, 0);
  requested_points := v_requested;
  applied_points := v_applied_points;
  discount_amount := floor(
    v_applied_points::numeric * v_rule.redeem_amount::numeric / v_rule.redeem_points::numeric
  )::integer;
  amount_before_discount := v_before;
  amount_after_discount := greatest(v_before - discount_amount, 0);
  min_redeem_points := v_rule.min_redeem_points;
  redeem_points := v_rule.redeem_points;
  redeem_amount := v_rule.redeem_amount;

  return next;
end;
$$;

create or replace function public.customer_list_reward_transactions(
  p_limit integer default 50
)
returns table(
  transaction_id uuid,
  transaction_type text,
  points_delta integer,
  balance_before integer,
  balance_after integer,
  rupiah_value integer,
  description text,
  reference_type text,
  order_no text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    rt.id,
    rt.transaction_type,
    rt.points_delta,
    rt.balance_before,
    rt.balance_after,
    rt.rupiah_value,
    coalesce(rt.description, ''),
    rt.reference_type,
    o.order_no,
    rt.created_at
  from public.reward_transactions rt
  left join public.orders o on o.id = rt.order_id
  where rt.account_user_id = auth.uid()
  order by rt.created_at desc
  limit greatest(coalesce(p_limit, 50), 1);
$$;

create or replace function public._apply_order_reward(
  p_order_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_rule public.reward_rules%rowtype;
  v_account public.reward_accounts%rowtype;
  v_points integer := 0;
  v_balance_before integer := 0;
  v_balance_after integer := 0;
begin
  select *
  into v_order
  from public.orders
  where id = p_order_id
  limit 1
  for update;

  if v_order.id is null or v_order.user_id is null then
    return 0;
  end if;

  if v_order.order_status <> 'completed' or v_order.reward_processed_at is not null then
    return coalesce(v_order.reward_points_earned, 0);
  end if;

  v_rule := public._active_reward_rule();
  v_points := floor(
    greatest(coalesce(v_order.subtotal, 0) - coalesce(v_order.reward_discount_total, 0), 0)::numeric
    / v_rule.earn_amount_spent::numeric
  )::integer * v_rule.earn_points;

  v_account := public._ensure_reward_account(v_order.user_id);
  v_balance_before := coalesce(v_account.current_balance, 0);
  v_balance_after := v_balance_before + v_points;

  if v_points > 0 then
    update public.reward_accounts
    set
      current_balance = v_balance_after,
      lifetime_earned = lifetime_earned + v_points,
      updated_at = now()
    where user_id = v_order.user_id;

    insert into public.reward_transactions (
      account_user_id,
      order_id,
      transaction_type,
      points_delta,
      balance_before,
      balance_after,
      rupiah_value,
      description,
      reference_type,
      reference_id
    )
    values (
      v_order.user_id,
      v_order.id,
      'earn',
      v_points,
      v_balance_before,
      v_balance_after,
      0,
      'Poin masuk dari pesanan selesai ' || coalesce(v_order.order_no, ''),
      'order',
      v_order.id
    );
  end if;

  update public.orders
  set
    reward_points_earned = v_points,
    reward_processed_at = now(),
    updated_at = now()
  where id = v_order.id;

  return v_points;
end;
$$;

alter table public.reward_rules enable row level security;
alter table public.reward_accounts enable row level security;
alter table public.reward_transactions enable row level security;

drop policy if exists "authenticated can read active reward rules" on public.reward_rules;
create policy "authenticated can read active reward rules"
on public.reward_rules
for select
to authenticated
using (is_active = true);

drop policy if exists "users read own reward account" on public.reward_accounts;
create policy "users read own reward account"
on public.reward_accounts
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users read own reward transactions" on public.reward_transactions;
create policy "users read own reward transactions"
on public.reward_transactions
for select
to authenticated
using (auth.uid() = account_user_id);

drop function if exists public.customer_place_order(jsonb, text, text, uuid, uuid, text, text, text);
create function public.customer_place_order(
  p_items jsonb,
  p_payment_method_code text,
  p_order_type text default 'delivery',
  p_requested_branch_id uuid default null,
  p_address_id uuid default null,
  p_delivery_label text default null,
  p_delivery_address text default null,
  p_notes text default null,
  p_service_fee integer default 1500,
  p_redeem_points integer default 0
)
returns table(
  order_id uuid,
  order_no text,
  placed_at timestamptz,
  order_status text,
  payment_status text,
  order_type text,
  grand_total integer,
  subtotal integer,
  delivery_fee integer,
  service_fee integer,
  branch_id uuid,
  branch_name text,
  wallet_balance integer,
  reward_balance integer,
  reward_points_redeemed integer,
  reward_discount_total integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_branch_id uuid;
  v_branch_name text;
  v_payment_method_code text := lower(trim(coalesce(p_payment_method_code, 'wallet')));
  v_payment_method_id uuid;
  v_order_id uuid;
  v_order_no text;
  v_order_type text := lower(trim(coalesce(p_order_type, 'delivery')));
  v_payment_status text;
  v_order_status text;
  v_delivery_fee integer := 0;
  v_service_fee integer := greatest(coalesce(p_service_fee, 0), 0);
  v_subtotal integer := 0;
  v_grand_total integer := 0;
  v_wallet_balance integer := 0;
  v_reward_balance integer := 0;
  v_customer_name text;
  v_customer_phone text;
  v_item jsonb;
  v_product_id text;
  v_qty integer;
  v_stock_before integer;
  v_stock_after integer;
  v_price integer;
  v_branch_product_id uuid;
  v_placed_at timestamptz;
  v_rule public.reward_rules%rowtype;
  v_account public.reward_accounts%rowtype;
  v_redeem_points integer := greatest(coalesce(p_redeem_points, 0), 0);
  v_redeem_discount integer := 0;
  v_redeem_max_points integer := 0;
  v_reward_balance_before integer := 0;
begin
  if v_user_id is null then
    raise exception 'User belum login.';
  end if;

  if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang pesanan kosong.';
  end if;

  if v_order_type not in ('delivery', 'pickup') then
    raise exception 'Jenis pesanan tidak valid.';
  end if;

  if v_payment_method_code not in ('wallet', 'transfer_bca', 'cash') then
    raise exception 'Metode pembayaran tidak valid.';
  end if;

  v_branch_id := public._resolve_customer_checkout_branch_id(p_requested_branch_id);
  if v_branch_id is null then
    raise exception 'Cabang aktif tidak ditemukan untuk checkout.';
  end if;

  select b.name
  into v_branch_name
  from public.branches b
  where b.id = v_branch_id
  limit 1;

  if v_branch_name is null then
    raise exception 'Data cabang checkout tidak ditemukan.';
  end if;

  if v_payment_method_code <> 'wallet' then
    select pm.id
    into v_payment_method_id
    from public.payment_methods pm
    where pm.code = v_payment_method_code
      and pm.is_active = true
    limit 1;

    if v_payment_method_id is null then
      raise exception 'Metode pembayaran belum aktif di sistem.';
    end if;
  end if;

  select
    coalesce(nullif(trim(p.full_name), ''), split_part(coalesce(u.email, 'Member'), '@', 1)),
    nullif(trim(p.phone), '')
  into v_customer_name, v_customer_phone
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = v_user_id;

  for v_item in
    select value
    from jsonb_array_elements(p_items)
  loop
    v_product_id := nullif(trim(v_item ->> 'product_id'), '');
    v_qty := greatest(coalesce((v_item ->> 'qty')::integer, 0), 0);

    if v_product_id is null or v_qty <= 0 then
      raise exception 'Item pesanan tidak valid.';
    end if;

    select
      bp.id,
      bp.stock_on_hand,
      bp.selling_price
    into
      v_branch_product_id,
      v_stock_before,
      v_price
    from public.branch_products bp
    inner join public.products p on p.id = bp.product_id
    where bp.branch_id = v_branch_id
      and bp.product_id = v_product_id
      and bp.is_active = true
      and p.is_active = true
    limit 1
    for update of bp;

    if v_branch_product_id is null then
      raise exception 'Produk % belum tersedia di cabang terpilih.', v_product_id;
    end if;

    if v_stock_before < v_qty then
      raise exception 'Stok produk % tidak mencukupi. Sisa stok %.', v_product_id, v_stock_before;
    end if;

    v_subtotal := v_subtotal + (v_price * v_qty);
  end loop;

  v_delivery_fee := case when v_order_type = 'delivery' then 8000 else 0 end;
  v_grand_total := v_subtotal + v_delivery_fee + v_service_fee;
  v_payment_status := case when v_payment_method_code = 'wallet' then 'paid' else 'unpaid' end;
  v_order_status := case
    when v_payment_method_code = 'wallet' then 'processing'
    else 'pending'
  end;

  if v_redeem_points > 0 then
    v_rule := public._active_reward_rule();
    v_account := public._ensure_reward_account(v_user_id);
    v_reward_balance_before := coalesce(v_account.current_balance, 0);
    v_redeem_max_points := floor(
      v_grand_total::numeric * v_rule.redeem_points::numeric / v_rule.redeem_amount::numeric
    )::integer;
    v_redeem_points := least(v_redeem_points, v_reward_balance_before, v_redeem_max_points);

    if v_redeem_points < v_rule.min_redeem_points then
      raise exception 'Minimal redeem Mepu Point adalah % poin.', v_rule.min_redeem_points;
    end if;

    v_redeem_discount := floor(
      v_redeem_points::numeric * v_rule.redeem_amount::numeric / v_rule.redeem_points::numeric
    )::integer;
    v_grand_total := greatest(v_grand_total - v_redeem_discount, 0);

    update public.reward_accounts
    set
      current_balance = current_balance - v_redeem_points,
      lifetime_redeemed = lifetime_redeemed + v_redeem_points,
      updated_at = now()
    where user_id = v_user_id
    returning current_balance into v_reward_balance;

    insert into public.reward_transactions (
      account_user_id,
      transaction_type,
      points_delta,
      balance_before,
      balance_after,
      rupiah_value,
      description,
      reference_type,
      created_by
    )
    values (
      v_user_id,
      'redeem',
      -v_redeem_points,
      v_reward_balance_before,
      v_reward_balance,
      v_redeem_discount,
      'Redeem Mepu Point untuk checkout',
      'order',
      v_user_id
    );
  else
    select coalesce(current_balance, 0)
    into v_reward_balance
    from public.reward_accounts
    where user_id = v_user_id;
  end if;

  if v_payment_method_code = 'wallet' then
    select p.wallet_balance
    into v_wallet_balance
    from public.profiles p
    where p.id = v_user_id
    for update;

    if coalesce(v_wallet_balance, 0) < v_grand_total then
      raise exception 'Saldo MepuPoin tidak cukup untuk checkout.';
    end if;

    update public.profiles
    set
      wallet_balance = public.profiles.wallet_balance - v_grand_total,
      updated_at = now()
    where id = v_user_id
    returning public.profiles.wallet_balance into v_wallet_balance;
  else
    select coalesce(p.wallet_balance, 0)
    into v_wallet_balance
    from public.profiles p
    where p.id = v_user_id;
  end if;

  insert into public.orders (
    user_id,
    branch_id,
    address_id,
    payment_method_id,
    order_type,
    order_status,
    payment_status,
    customer_name,
    customer_phone,
    delivery_label,
    delivery_address,
    subtotal,
    discount_total,
    delivery_fee,
    service_fee,
    grand_total,
    notes,
    reward_points_redeemed,
    reward_discount_total
  )
  values (
    v_user_id,
    v_branch_id,
    case when v_order_type = 'delivery' then p_address_id else null end,
    v_payment_method_id,
    v_order_type,
    v_order_status,
    v_payment_status,
    v_customer_name,
    v_customer_phone,
    case when v_order_type = 'delivery' then nullif(trim(coalesce(p_delivery_label, '')), '') else null end,
    case when v_order_type = 'delivery' then nullif(trim(coalesce(p_delivery_address, '')), '') else null end,
    v_subtotal,
    v_redeem_discount,
    v_delivery_fee,
    v_service_fee,
    v_grand_total,
    nullif(trim(coalesce(p_notes, '')), ''),
    v_redeem_points,
    v_redeem_discount
  )
  returning id, public.orders.order_no, public.orders.placed_at
  into v_order_id, v_order_no, v_placed_at;

  if v_redeem_points > 0 then
    update public.reward_transactions
    set
      order_id = v_order_id,
      reference_id = v_order_id
    where id = (
      select rt.id
      from public.reward_transactions rt
      where rt.account_user_id = v_user_id
        and rt.order_id is null
        and rt.transaction_type = 'redeem'
        and rt.description = 'Redeem Mepu Point untuk checkout'
      order by rt.created_at desc
      limit 1
    );
  end if;

  for v_item in
    select value
    from jsonb_array_elements(p_items)
  loop
    v_product_id := nullif(trim(v_item ->> 'product_id'), '');
    v_qty := greatest(coalesce((v_item ->> 'qty')::integer, 0), 0);

    select
      bp.id,
      bp.stock_on_hand,
      bp.selling_price
    into
      v_branch_product_id,
      v_stock_before,
      v_price
    from public.branch_products bp
    where bp.branch_id = v_branch_id
      and bp.product_id = v_product_id
    limit 1
    for update of bp;

    v_stock_after := greatest(v_stock_before - v_qty, 0);

    insert into public.order_items (
      order_id,
      branch_product_id,
      product_id,
      product_name,
      sku,
      qty,
      unit_price,
      discount_amount,
      subtotal
    )
    select
      v_order_id,
      bp.id,
      bp.product_id,
      p.name,
      coalesce(p.sku, bp.product_id),
      v_qty,
      bp.selling_price,
      0,
      bp.selling_price * v_qty
    from public.branch_products bp
    inner join public.products p on p.id = bp.product_id
    where bp.id = v_branch_product_id;

    update public.branch_products
    set
      stock_on_hand = v_stock_after,
      updated_at = now()
    where id = v_branch_product_id;

    update public.products
    set
      stock = v_stock_after,
      updated_at = now()
    where id = v_product_id;

    insert into public.stock_movements (
      branch_product_id,
      branch_id,
      product_id,
      movement_type,
      qty_change,
      qty_before,
      qty_after,
      reference_type,
      reference_id,
      notes,
      performed_by
    )
    values (
      v_branch_product_id,
      v_branch_id,
      v_product_id,
      'sale',
      -v_qty,
      v_stock_before,
      v_stock_after,
      'order',
      v_order_id,
      'Checkout customer',
      v_user_id
    );
  end loop;

  return query
  select
    v_order_id,
    v_order_no,
    v_placed_at,
    v_order_status,
    v_payment_status,
    v_order_type,
    v_grand_total,
    v_subtotal,
    v_delivery_fee,
    v_service_fee,
    v_branch_id,
    v_branch_name,
    coalesce(v_wallet_balance, 0),
    coalesce(v_reward_balance, 0),
    coalesce(v_redeem_points, 0),
    coalesce(v_redeem_discount, 0);
end;
$$;

create or replace function public.branch_admin_update_order_status(
  p_order_id uuid,
  p_next_status text,
  p_courier_name text default null,
  p_courier_phone text default null
)
returns table(
  order_id uuid,
  order_status text,
  payment_status text,
  courier_name text,
  courier_phone text,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_next_status text := lower(trim(coalesce(p_next_status, '')));
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  limit 1
  for update;

  if v_order.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_order.branch_id is null or not public.is_branch_admin(v_order.branch_id) then
    raise exception 'Anda tidak memiliki akses ke pesanan cabang ini.';
  end if;

  if v_next_status not in (
    'pending',
    'confirmed',
    'processing',
    'ready_pickup',
    'out_for_delivery',
    'completed',
    'cancelled'
  ) then
    raise exception 'Status pesanan tidak valid.';
  end if;

  if not public._branch_admin_can_transition_order(v_order.order_type, v_order.order_status, v_next_status) then
    raise exception 'Transisi status dari % ke % tidak diizinkan.', v_order.order_status, v_next_status;
  end if;

  if v_order.order_type = 'delivery'
     and v_next_status = 'out_for_delivery'
     and nullif(trim(coalesce(p_courier_name, '')), '') is null then
    raise exception 'Nama kurir wajib diisi sebelum pesanan dikirim.';
  end if;

  update public.orders
  set
    order_status = v_next_status,
    courier_name = case
      when v_order.order_type = 'delivery' and v_next_status = 'out_for_delivery'
        then nullif(trim(coalesce(p_courier_name, '')), '')
      else public.orders.courier_name
    end,
    courier_phone = case
      when v_order.order_type = 'delivery' and v_next_status = 'out_for_delivery'
        then nullif(trim(coalesce(p_courier_phone, '')), '')
      else public.orders.courier_phone
    end,
    completed_at = case when v_next_status = 'completed' then now() else null end,
    updated_at = now()
  where id = v_order.id
  returning
    public.orders.id,
    public.orders.order_status,
    public.orders.payment_status,
    public.orders.courier_name,
    public.orders.courier_phone,
    public.orders.completed_at
  into order_id, order_status, payment_status, courier_name, courier_phone, completed_at;

  if v_next_status = 'completed' then
    perform public._apply_order_reward(v_order.id);
  end if;

  return next;
end;
$$;

grant execute on function public.customer_get_reward_summary() to authenticated;
grant execute on function public.customer_preview_reward_redeem(integer, integer, integer, integer) to authenticated;
grant execute on function public.customer_list_reward_transactions(integer) to authenticated;
grant execute on function public.customer_place_order(jsonb, text, text, uuid, uuid, text, text, text, integer, integer) to authenticated;
