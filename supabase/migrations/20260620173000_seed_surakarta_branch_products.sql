with branch_map as (
  select id, code
  from public.branches
  where code in ('KDMP-SLO-01', 'KDMP-SLO-02')
),
seed_data as (
  select *
  from (
    values
      ('KDMP-SLO-01', 'rice', 66500, 82000, 28, true),
      ('KDMP-SLO-01', 'oil', 32500, 38000, 40, true),
      ('KDMP-SLO-01', 'smartband', 205000, 249000, 10, true),
      ('KDMP-SLO-01', 'honey', 47000, 52000, 16, false),
      ('KDMP-SLO-01', 'coffee', 23500, 28000, 30, true),
      ('KDMP-SLO-01', 'powerbank', 149000, 175000, 9, false),
      ('KDMP-SLO-02', 'rice', 65500, 82000, 18, true),
      ('KDMP-SLO-02', 'oil', 31900, 38000, 26, true),
      ('KDMP-SLO-02', 'smartband', 199000, 249000, 6, false),
      ('KDMP-SLO-02', 'honey', 45500, 52000, 21, true),
      ('KDMP-SLO-02', 'coffee', 22900, 28000, 19, true),
      ('KDMP-SLO-02', 'powerbank', 145000, 175000, 12, false)
  ) as t(branch_code, product_id, selling_price, original_price, stock_on_hand, is_featured)
)
insert into public.branch_products (
  branch_id,
  product_id,
  selling_price,
  original_price,
  stock_on_hand,
  stock_reserved,
  min_stock_alert,
  is_active,
  is_featured
)
select
  b.id,
  s.product_id,
  s.selling_price,
  s.original_price,
  s.stock_on_hand,
  0,
  5,
  true,
  s.is_featured
from seed_data s
join branch_map b
  on b.code = s.branch_code
join public.products p
  on p.id = s.product_id
on conflict (branch_id, product_id) do update
set
  selling_price = excluded.selling_price,
  original_price = excluded.original_price,
  stock_on_hand = excluded.stock_on_hand,
  stock_reserved = excluded.stock_reserved,
  min_stock_alert = excluded.min_stock_alert,
  is_active = excluded.is_active,
  is_featured = excluded.is_featured,
  updated_at = now();
