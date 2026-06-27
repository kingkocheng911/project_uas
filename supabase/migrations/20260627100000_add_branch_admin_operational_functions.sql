create or replace function public._current_branch_admin_branch_id()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  select ba.branch_id
  into v_branch_id
  from public.branch_admins ba
  where ba.user_id = auth.uid()
    and ba.is_active = true
  order by ba.is_primary desc, ba.assigned_at asc
  limit 1;

  if v_branch_id is null then
    raise exception 'Akun admin ini belum terhubung ke cabang aktif.';
  end if;

  return v_branch_id;
end;
$$;

create or replace function public.branch_admin_dashboard_summary()
returns table(
  branch_id uuid,
  branch_name text,
  total_sales_today integer,
  total_orders_today integer,
  pending_orders integer,
  processing_orders integer,
  delivery_orders integer,
  completed_orders integer,
  low_stock_products integer,
  out_of_stock_products integer,
  total_products integer,
  total_stock_units integer,
  today_revenue integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid := public._current_branch_admin_branch_id();
begin
  return query
  with branch_ctx as (
    select b.id, b.name
    from public.branches b
    where b.id = v_branch_id
    limit 1
  ),
  today_orders as (
    select o.*
    from public.orders o
    where o.branch_id = v_branch_id
      and o.placed_at >= date_trunc('day', now())
      and o.placed_at < date_trunc('day', now()) + interval '1 day'
  ),
  all_orders as (
    select o.*
    from public.orders o
    where o.branch_id = v_branch_id
  ),
  branch_products as (
    select
      bp.id,
      bp.stock_on_hand,
      bp.min_stock_alert,
      bp.is_active
    from public.branch_products bp
    where bp.branch_id = v_branch_id
  )
  select
    bc.id,
    bc.name,
    coalesce((
      select sum(o.grand_total)::integer
      from today_orders o
      where o.order_status = 'completed'
    ), 0) as total_sales_today,
    coalesce((select count(*)::integer from today_orders), 0) as total_orders_today,
    coalesce((
      select count(*)::integer
      from all_orders o
      where o.order_status = 'pending'
    ), 0) as pending_orders,
    coalesce((
      select count(*)::integer
      from all_orders o
      where o.order_status in ('confirmed', 'processing')
    ), 0) as processing_orders,
    coalesce((
      select count(*)::integer
      from all_orders o
      where o.order_status in ('out_for_delivery', 'ready_pickup')
    ), 0) as delivery_orders,
    coalesce((
      select count(*)::integer
      from all_orders o
      where o.order_status = 'completed'
    ), 0) as completed_orders,
    coalesce((
      select count(*)::integer
      from branch_products bp
      where bp.is_active = true
        and bp.stock_on_hand > 0
        and bp.stock_on_hand <= greatest(coalesce(nullif(bp.min_stock_alert, 0), 5), 1)
    ), 0) as low_stock_products,
    coalesce((
      select count(*)::integer
      from branch_products bp
      where bp.is_active = true
        and bp.stock_on_hand <= 0
    ), 0) as out_of_stock_products,
    coalesce((
      select count(*)::integer
      from branch_products bp
      where bp.is_active = true
    ), 0) as total_products,
    coalesce((
      select sum(greatest(bp.stock_on_hand, 0))::integer
      from branch_products bp
      where bp.is_active = true
    ), 0) as total_stock_units,
    coalesce((
      select sum(o.grand_total)::integer
      from today_orders o
      where o.order_status = 'completed'
    ), 0) as today_revenue
  from branch_ctx bc;
end;
$$;

create or replace function public.branch_admin_report_summary(
  p_from date default current_date,
  p_to date default current_date
)
returns table(
  branch_id uuid,
  branch_name text,
  report_from date,
  report_to date,
  daily_sales integer,
  daily_transactions integer,
  completed_transactions integer,
  gross_revenue integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid := public._current_branch_admin_branch_id();
  v_from date := least(coalesce(p_from, current_date), coalesce(p_to, current_date));
  v_to date := greatest(coalesce(p_from, current_date), coalesce(p_to, current_date));
begin
  return query
  select
    b.id,
    b.name,
    v_from,
    v_to,
    coalesce(sum(case when o.order_status = 'completed' then o.grand_total else 0 end), 0)::integer as daily_sales,
    count(o.id)::integer as daily_transactions,
    count(*) filter (where o.order_status = 'completed')::integer as completed_transactions,
    coalesce(sum(case when o.order_status = 'completed' then o.grand_total else 0 end), 0)::integer as gross_revenue
  from public.branches b
  left join public.orders o
    on o.branch_id = b.id
   and timezone('Asia/Jakarta', o.placed_at)::date between v_from and v_to
  where b.id = v_branch_id
  group by b.id, b.name;
end;
$$;

create or replace function public.branch_admin_report_top_products(
  p_from date default current_date,
  p_to date default current_date,
  p_limit integer default 5
)
returns table(
  product_id text,
  product_name text,
  total_qty integer,
  total_revenue integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid := public._current_branch_admin_branch_id();
  v_from date := least(coalesce(p_from, current_date), coalesce(p_to, current_date));
  v_to date := greatest(coalesce(p_from, current_date), coalesce(p_to, current_date));
begin
  return query
  select
    oi.product_id,
    max(oi.product_name) as product_name,
    coalesce(sum(oi.qty), 0)::integer as total_qty,
    coalesce(sum(oi.subtotal), 0)::integer as total_revenue
  from public.order_items oi
  inner join public.orders o on o.id = oi.order_id
  where o.branch_id = v_branch_id
    and timezone('Asia/Jakarta', o.placed_at)::date between v_from and v_to
    and o.order_status = 'completed'
  group by oi.product_id
  order by total_qty desc, total_revenue desc, product_name asc
  limit greatest(coalesce(p_limit, 5), 1);
end;
$$;

create or replace function public.branch_admin_upsert_promotion(
  p_promotion_id uuid default null,
  p_title text default null,
  p_description text default null,
  p_promo_type text default 'percentage',
  p_promo_scope text default 'all_products',
  p_discount_value integer default 0,
  p_min_purchase integer default null,
  p_max_discount integer default null,
  p_start_at timestamptz default null,
  p_end_at timestamptz default null,
  p_is_active boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid := public._current_branch_admin_branch_id();
  v_promotion_id uuid;
begin
  if trim(coalesce(p_title, '')) = '' then
    raise exception 'Judul promo wajib diisi.';
  end if;

  if coalesce(p_start_at, now()) >= coalesce(p_end_at, now() + interval '1 day') then
    raise exception 'Periode promo tidak valid.';
  end if;

  if p_promotion_id is null then
    insert into public.promotions (
      branch_id,
      title,
      description,
      promo_type,
      promo_scope,
      discount_value,
      min_purchase,
      max_discount,
      start_at,
      end_at,
      is_active,
      created_by
    )
    values (
      v_branch_id,
      trim(p_title),
      nullif(trim(coalesce(p_description, '')), ''),
      lower(trim(coalesce(p_promo_type, 'percentage'))),
      lower(trim(coalesce(p_promo_scope, 'all_products'))),
      greatest(coalesce(p_discount_value, 0), 0),
      case when p_min_purchase is null then null else greatest(p_min_purchase, 0) end,
      case when p_max_discount is null then null else greatest(p_max_discount, 0) end,
      coalesce(p_start_at, now()),
      coalesce(p_end_at, now() + interval '7 days'),
      coalesce(p_is_active, true),
      auth.uid()
    )
    returning id into v_promotion_id;
  else
    update public.promotions
    set
      title = trim(p_title),
      description = nullif(trim(coalesce(p_description, '')), ''),
      promo_type = lower(trim(coalesce(p_promo_type, 'percentage'))),
      promo_scope = lower(trim(coalesce(p_promo_scope, 'all_products'))),
      discount_value = greatest(coalesce(p_discount_value, 0), 0),
      min_purchase = case when p_min_purchase is null then null else greatest(p_min_purchase, 0) end,
      max_discount = case when p_max_discount is null then null else greatest(p_max_discount, 0) end,
      start_at = coalesce(p_start_at, public.promotions.start_at),
      end_at = coalesce(p_end_at, public.promotions.end_at),
      is_active = coalesce(p_is_active, public.promotions.is_active),
      updated_at = now()
    where id = p_promotion_id
      and branch_id = v_branch_id
    returning id into v_promotion_id;

    if v_promotion_id is null then
      raise exception 'Promo cabang tidak ditemukan.';
    end if;
  end if;

  return v_promotion_id;
end;
$$;

create or replace function public.branch_admin_toggle_promotion(
  p_promotion_id uuid,
  p_is_active boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid := public._current_branch_admin_branch_id();
  v_promotion_id uuid;
begin
  update public.promotions
  set
    is_active = coalesce(p_is_active, false),
    updated_at = now()
  where id = p_promotion_id
    and branch_id = v_branch_id
  returning id into v_promotion_id;

  if v_promotion_id is null then
    raise exception 'Promo cabang tidak ditemukan.';
  end if;

  return v_promotion_id;
end;
$$;

grant execute on function public.branch_admin_dashboard_summary() to authenticated;
grant execute on function public.branch_admin_report_summary(date, date) to authenticated;
grant execute on function public.branch_admin_report_top_products(date, date, integer) to authenticated;
grant execute on function public.branch_admin_upsert_promotion(uuid, text, text, text, text, integer, integer, integer, timestamptz, timestamptz, boolean) to authenticated;
grant execute on function public.branch_admin_toggle_promotion(uuid, boolean) to authenticated;
