create or replace function public._assert_superadmin()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_superadmin() then
    raise exception 'Akses hanya untuk Super Admin.';
  end if;
end;
$$;

create or replace function public.superadmin_global_dashboard_summary()
returns table(
  total_branches integer,
  active_branches integer,
  total_customers integer,
  total_branch_admins integer,
  total_transactions_today integer,
  total_revenue_today bigint,
  total_revenue_month bigint,
  total_products integer,
  out_of_stock_products integer,
  low_stock_products integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with branch_summary as (
    select
      count(*)::integer as total_branches,
      count(*) filter (where is_active = true)::integer as active_branches
    from public.branches
  ),
  customer_summary as (
    select count(*)::integer as total_customers
    from public.profiles
    where coalesce(role_type, '') = 'customer'
       or coalesce(role, '') = 'user'
  ),
  admin_summary as (
    select count(*)::integer as total_branch_admins
    from public.branch_admins
    where is_active = true
  ),
  order_summary as (
    select
      count(*) filter (where placed_at::date = current_date)::integer as total_transactions_today,
      coalesce(sum(case
        when payment_status = 'paid' and placed_at::date = current_date
          then grand_total else 0 end), 0)::bigint as total_revenue_today,
      coalesce(sum(case
        when payment_status = 'paid'
         and date_trunc('month', placed_at) = date_trunc('month', now())
          then grand_total else 0 end), 0)::bigint as total_revenue_month
    from public.orders
  ),
  product_summary as (
    select
      count(*)::integer as total_products,
      count(*) filter (where stock_on_hand <= 0)::integer as out_of_stock_products,
      count(*) filter (
        where stock_on_hand > 0
          and stock_on_hand <= greatest(coalesce(min_stock_alert, 0), 5)
      )::integer as low_stock_products
    from public.branch_products
    where is_active = true
  )
  select
    bs.total_branches,
    bs.active_branches,
    cs.total_customers,
    ads.total_branch_admins,
    os.total_transactions_today,
    os.total_revenue_today,
    os.total_revenue_month,
    ps.total_products,
    ps.out_of_stock_products,
    ps.low_stock_products
  from branch_summary bs
  cross join customer_summary cs
  cross join admin_summary ads
  cross join order_summary os
  cross join product_summary ps;
end;
$$;

create or replace function public.superadmin_branch_monitoring()
returns table(
  branch_id uuid,
  branch_code text,
  branch_name text,
  phone text,
  email text,
  address text,
  province text,
  city text,
  district text,
  postal_code text,
  is_active boolean,
  transactions_today integer,
  revenue_today bigint,
  pending_orders integer,
  total_stock bigint,
  out_of_stock_products integer,
  low_stock_products integer,
  health_status text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with order_stats as (
    select
      o.branch_id,
      count(*) filter (where o.placed_at::date = current_date)::integer as transactions_today,
      coalesce(sum(case
        when o.payment_status = 'paid' and o.placed_at::date = current_date
          then o.grand_total else 0 end), 0)::bigint as revenue_today,
      count(*) filter (where o.order_status = 'pending')::integer as pending_orders
    from public.orders o
    where o.branch_id is not null
    group by o.branch_id
  ),
  stock_stats as (
    select
      bp.branch_id,
      coalesce(sum(bp.stock_on_hand), 0)::bigint as total_stock,
      count(*) filter (where bp.stock_on_hand <= 0 and bp.is_active = true)::integer as out_of_stock_products,
      count(*) filter (
        where bp.stock_on_hand > 0
          and bp.stock_on_hand <= greatest(coalesce(bp.min_stock_alert, 0), 5)
          and bp.is_active = true
      )::integer as low_stock_products
    from public.branch_products bp
    group by bp.branch_id
  )
  select
    b.id,
    b.code,
    b.name,
    coalesce(b.phone, ''),
    coalesce(b.email, ''),
    b.address,
    coalesce(b.province, ''),
    coalesce(b.city, ''),
    coalesce(b.district, ''),
    coalesce(b.postal_code, ''),
    b.is_active,
    coalesce(os.transactions_today, 0),
    coalesce(os.revenue_today, 0),
    coalesce(os.pending_orders, 0),
    coalesce(ss.total_stock, 0),
    coalesce(ss.out_of_stock_products, 0),
    coalesce(ss.low_stock_products, 0),
    case
      when b.is_active = false then 'Perlu Perhatian'
      when coalesce(ss.out_of_stock_products, 0) >= 5 or coalesce(os.pending_orders, 0) >= 10 then 'Kritis'
      when coalesce(ss.low_stock_products, 0) >= 5 or coalesce(os.pending_orders, 0) >= 5 then 'Perlu Perhatian'
      else 'Normal'
    end as health_status
  from public.branches b
  left join order_stats os on os.branch_id = b.id
  left join stock_stats ss on ss.branch_id = b.id
  order by
    case
      when b.is_active = false then 2
      when coalesce(ss.out_of_stock_products, 0) >= 5 or coalesce(os.pending_orders, 0) >= 10 then 3
      when coalesce(ss.low_stock_products, 0) >= 5 or coalesce(os.pending_orders, 0) >= 5 then 2
      else 1
    end desc,
    b.name asc;
end;
$$;

create or replace function public.superadmin_branch_performance()
returns table(
  branch_id uuid,
  branch_name text,
  revenue_today bigint,
  revenue_month bigint,
  previous_revenue_month bigint,
  transactions_today integer,
  transactions_month integer,
  growth_percent numeric,
  performance_score numeric
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with current_month as (
    select
      o.branch_id,
      coalesce(sum(case when o.payment_status = 'paid' then o.grand_total else 0 end), 0)::bigint as revenue_month,
      count(*)::integer as transactions_month
    from public.orders o
    where o.branch_id is not null
      and date_trunc('month', o.placed_at) = date_trunc('month', now())
    group by o.branch_id
  ),
  previous_month as (
    select
      o.branch_id,
      coalesce(sum(case when o.payment_status = 'paid' then o.grand_total else 0 end), 0)::bigint as previous_revenue_month
    from public.orders o
    where o.branch_id is not null
      and date_trunc('month', o.placed_at) = date_trunc('month', now() - interval '1 month')
    group by o.branch_id
  ),
  current_day as (
    select
      o.branch_id,
      coalesce(sum(case when o.payment_status = 'paid' then o.grand_total else 0 end), 0)::bigint as revenue_today,
      count(*)::integer as transactions_today
    from public.orders o
    where o.branch_id is not null
      and o.placed_at::date = current_date
    group by o.branch_id
  )
  select
    b.id,
    b.name,
    coalesce(cd.revenue_today, 0),
    coalesce(cm.revenue_month, 0),
    coalesce(pm.previous_revenue_month, 0),
    coalesce(cd.transactions_today, 0),
    coalesce(cm.transactions_month, 0),
    case
      when coalesce(pm.previous_revenue_month, 0) <= 0 and coalesce(cm.revenue_month, 0) > 0 then 100
      when coalesce(pm.previous_revenue_month, 0) <= 0 then 0
      else round(((coalesce(cm.revenue_month, 0) - pm.previous_revenue_month)::numeric / pm.previous_revenue_month::numeric) * 100, 2)
    end as growth_percent,
    round(
      least(
        100,
        (
          least(coalesce(cm.revenue_month, 0)::numeric / 100000, 60) +
          least(coalesce(cm.transactions_month, 0)::numeric * 1.5, 25) +
          least(greatest(
            case
              when coalesce(pm.previous_revenue_month, 0) <= 0 and coalesce(cm.revenue_month, 0) > 0 then 15
              when coalesce(pm.previous_revenue_month, 0) <= 0 then 0
              else ((coalesce(cm.revenue_month, 0) - pm.previous_revenue_month)::numeric / pm.previous_revenue_month::numeric) * 15
            end, 0
          ), 15)
        )
      ),
      2
    ) as performance_score
  from public.branches b
  left join current_month cm on cm.branch_id = b.id
  left join previous_month pm on pm.branch_id = b.id
  left join current_day cd on cd.branch_id = b.id
  order by performance_score desc, revenue_month desc, b.name asc;
end;
$$;

create or replace function public.superadmin_kpi_summary()
returns table(
  average_order_value numeric,
  conversion_order numeric,
  repeat_customer integer,
  total_reward_redeemed integer,
  total_reward_earned integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with month_orders as (
    select *
    from public.orders
    where date_trunc('month', placed_at) = date_trunc('month', now())
  ),
  paid_orders as (
    select *
    from month_orders
    where payment_status = 'paid'
  ),
  repeat_customers as (
    select count(*)::integer as repeat_customer
    from (
      select user_id
      from public.orders
      where payment_status = 'paid'
      group by user_id
      having count(*) >= 2
    ) t
  )
  select
    coalesce(round((sum(paid_orders.grand_total)::numeric / nullif(count(*), 0)), 2), 0) as average_order_value,
    coalesce(round((
      (select count(*) from month_orders where order_status = 'completed')::numeric /
      nullif((select count(*) from month_orders), 0)
    ) * 100, 2), 0) as conversion_order,
    (select repeat_customer from repeat_customers),
    coalesce((select sum(reward_points_redeemed) from month_orders), 0)::integer as total_reward_redeemed,
    coalesce((select sum(reward_points_earned) from month_orders), 0)::integer as total_reward_earned
  from paid_orders;
end;
$$;

create or replace function public.superadmin_admin_monitoring()
returns table(
  branch_admin_id uuid,
  branch_id uuid,
  branch_name text,
  branch_code text,
  full_name text,
  email text,
  phone text,
  admin_role text,
  is_primary boolean,
  is_active boolean,
  last_login_at timestamptz,
  managed_transactions integer
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  perform public._assert_superadmin();

  return query
  with managed as (
    select branch_id, count(*)::integer as managed_transactions
    from public.orders
    where branch_id is not null
    group by branch_id
  )
  select
    ba.id,
    ba.branch_id,
    b.name,
    b.code,
    coalesce(p.full_name, ''),
    coalesce(au.email, ''),
    coalesce(p.phone, ''),
    ba.admin_role,
    ba.is_primary,
    ba.is_active,
    au.last_sign_in_at,
    coalesce(m.managed_transactions, 0)
  from public.branch_admins ba
  join public.branches b on b.id = ba.branch_id
  left join public.profiles p on p.id = ba.user_id
  left join auth.users au on au.id = ba.user_id
  left join managed m on m.branch_id = ba.branch_id
  order by ba.is_active desc, b.name asc, p.full_name asc;
end;
$$;

create or replace function public.superadmin_monthly_revenue_chart()
returns table(
  label text,
  amount bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with months as (
    select generate_series(
      date_trunc('month', now()) - interval '5 month',
      date_trunc('month', now()),
      interval '1 month'
    ) as month_start
  )
  select
    to_char(m.month_start, 'Mon YY') as label,
    coalesce(sum(o.grand_total) filter (where o.payment_status = 'paid'), 0)::bigint as amount
  from months m
  left join public.orders o
    on date_trunc('month', o.placed_at) = m.month_start
  group by m.month_start
  order by m.month_start;
end;
$$;

create or replace function public.superadmin_daily_transactions_chart()
returns table(
  label text,
  amount integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  with days as (
    select generate_series(current_date - 6, current_date, interval '1 day')::date as day_date
  )
  select
    to_char(d.day_date, 'DD Mon') as label,
    coalesce(count(o.id), 0)::integer as amount
  from days d
  left join public.orders o
    on o.placed_at::date = d.day_date
  group by d.day_date
  order by d.day_date;
end;
$$;

create or replace function public.superadmin_category_distribution_chart()
returns table(
  label text,
  amount bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  select
    coalesce((p.category_labels)[1], c.label, 'Tanpa Kategori') as label,
    coalesce(sum(oi.qty), 0)::bigint as amount
  from public.order_items oi
  left join public.products p on p.id = oi.product_id
  left join public.categories c on c.id = p.category_id
  group by coalesce((p.category_labels)[1], c.label, 'Tanpa Kategori')
  order by amount desc, label asc
  limit 6;
end;
$$;

create or replace function public.superadmin_payment_distribution_chart()
returns table(
  label text,
  amount bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  select
    coalesce(pm.name, pm.provider_name, pm.type, 'Tanpa Metode') as label,
    count(o.id)::bigint as amount
  from public.orders o
  left join public.payment_methods pm on pm.id = o.payment_method_id
  group by coalesce(pm.name, pm.provider_name, pm.type, 'Tanpa Metode')
  order by amount desc, label asc
  limit 6;
end;
$$;

create or replace function public.superadmin_reward_distribution_chart()
returns table(
  label text,
  amount bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  return query
  select 'Reward Earned'::text as label, coalesce(sum(reward_points_earned), 0)::bigint as amount
  from public.orders
  union all
  select 'Reward Redeemed'::text as label, coalesce(sum(reward_points_redeemed), 0)::bigint as amount
  from public.orders
  union all
  select 'Current Balance'::text as label, coalesce(sum(current_balance), 0)::bigint as amount
  from public.reward_accounts;
end;
$$;

create or replace function public.superadmin_upsert_branch(
  p_branch_id uuid default null,
  p_code text default null,
  p_name text default null,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_province text default null,
  p_city text default null,
  p_district text default null,
  p_postal_code text default null,
  p_is_active boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
begin
  perform public._assert_superadmin();

  if nullif(trim(coalesce(p_code, '')), '') is null then
    raise exception 'Kode cabang wajib diisi.';
  end if;

  if nullif(trim(coalesce(p_name, '')), '') is null then
    raise exception 'Nama cabang wajib diisi.';
  end if;

  if nullif(trim(coalesce(p_address, '')), '') is null then
    raise exception 'Alamat cabang wajib diisi.';
  end if;

  if p_branch_id is null then
    insert into public.branches (
      code, name, phone, email, address, province, city, district, postal_code, is_active
    )
    values (
      trim(p_code),
      trim(p_name),
      nullif(trim(coalesce(p_phone, '')), ''),
      nullif(trim(coalesce(p_email, '')), ''),
      trim(p_address),
      nullif(trim(coalesce(p_province, '')), ''),
      nullif(trim(coalesce(p_city, '')), ''),
      nullif(trim(coalesce(p_district, '')), ''),
      nullif(trim(coalesce(p_postal_code, '')), ''),
      coalesce(p_is_active, true)
    )
    returning id into v_branch_id;

    return v_branch_id;
  end if;

  update public.branches
  set
    code = trim(p_code),
    name = trim(p_name),
    phone = nullif(trim(coalesce(p_phone, '')), ''),
    email = nullif(trim(coalesce(p_email, '')), ''),
    address = trim(p_address),
    province = nullif(trim(coalesce(p_province, '')), ''),
    city = nullif(trim(coalesce(p_city, '')), ''),
    district = nullif(trim(coalesce(p_district, '')), ''),
    postal_code = nullif(trim(coalesce(p_postal_code, '')), ''),
    is_active = coalesce(p_is_active, true),
    updated_at = now()
  where id = p_branch_id;

  return p_branch_id;
end;
$$;

create or replace function public.superadmin_set_branch_active(
  p_branch_id uuid,
  p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_superadmin();

  update public.branches
  set
    is_active = p_is_active,
    updated_at = now()
  where id = p_branch_id;
end;
$$;

grant execute on function public._assert_superadmin() to authenticated;
grant execute on function public.superadmin_global_dashboard_summary() to authenticated;
grant execute on function public.superadmin_branch_monitoring() to authenticated;
grant execute on function public.superadmin_branch_performance() to authenticated;
grant execute on function public.superadmin_kpi_summary() to authenticated;
grant execute on function public.superadmin_admin_monitoring() to authenticated;
grant execute on function public.superadmin_monthly_revenue_chart() to authenticated;
grant execute on function public.superadmin_daily_transactions_chart() to authenticated;
grant execute on function public.superadmin_category_distribution_chart() to authenticated;
grant execute on function public.superadmin_payment_distribution_chart() to authenticated;
grant execute on function public.superadmin_reward_distribution_chart() to authenticated;
grant execute on function public.superadmin_upsert_branch(uuid, text, text, text, text, text, text, text, text, text, boolean) to authenticated;
grant execute on function public.superadmin_set_branch_active(uuid, boolean) to authenticated;
