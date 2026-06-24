drop policy if exists "branch admins manage own product image objects" on storage.objects;
create policy "branch admins manage own product image objects"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'product-images'
  and exists (
    select 1
    from public.branch_admins ba
    where ba.user_id = auth.uid()
      and ba.is_active = true
  )
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'product-images'
  and exists (
    select 1
    from public.branch_admins ba
    where ba.user_id = auth.uid()
      and ba.is_active = true
  )
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.branch_admin_create_product(
  p_branch_id uuid,
  p_name text,
  p_category_label text,
  p_price integer,
  p_original_price integer default null,
  p_stock integer default 0,
  p_description text default '',
  p_unit text default 'pcs',
  p_brand text default '',
  p_min_stock_alert integer default 0,
  p_is_featured boolean default false,
  p_image_url text default null
)
returns table(branch_product_id uuid, product_id text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_category_id uuid;
  v_product_id text;
  v_branch_product_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  if not public.is_branch_admin(p_branch_id) then
    raise exception 'Anda tidak memiliki akses ke cabang ini.';
  end if;

  select id
  into v_category_id
  from public.categories
  where label = p_category_label
    and is_active = true
  limit 1;

  if v_category_id is null then
    raise exception 'Kategori tidak ditemukan atau tidak aktif.';
  end if;

  v_product_id := 'branch-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 16);

  insert into public.products (
    id,
    name,
    price,
    original_price,
    stock,
    claimed_percent,
    reward_points,
    badge,
    description,
    icon_name,
    tone_hex,
    image_url,
    category_labels,
    highlights,
    related_ids,
    sort_order,
    sku,
    barcode,
    slug,
    category_id,
    unit,
    brand,
    weight_grams,
    is_active
  )
  values (
    v_product_id,
    trim(p_name),
    greatest(coalesce(p_price, 0), 0),
    greatest(coalesce(p_original_price, p_price, 0), 0),
    greatest(coalesce(p_stock, 0), 0),
    0,
    0,
    'Produk Cabang',
    coalesce(trim(p_description), ''),
    case lower(trim(p_category_label))
      when 'makanan' then 'restaurant_outlined'
      when 'minuman' then 'local_cafe_outlined'
      when 'obat' then 'local_pharmacy_outlined'
      when 'herbal' then 'spa_outlined'
      else 'shopping_basket_outlined'
    end,
    case lower(trim(p_category_label))
      when 'makanan' then '#C55A11'
      when 'minuman' then '#0E7490'
      when 'obat' then '#2563EB'
      when 'herbal' then '#2F855A'
      else '#B7791F'
    end,
    nullif(trim(coalesce(p_image_url, '')), ''),
    array[trim(p_category_label)],
    '{}'::text[],
    '{}'::text[],
    999,
    upper(substr(public.slugify(trim(p_name)), 1, 8)) || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4)),
    null,
    public.slugify(trim(p_name)) || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 6),
    v_category_id,
    coalesce(nullif(trim(p_unit), ''), 'pcs'),
    nullif(trim(p_brand), ''),
    null,
    true
  );

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
  values (
    p_branch_id,
    v_product_id,
    greatest(coalesce(p_price, 0), 0),
    greatest(coalesce(p_original_price, p_price, 0), 0),
    greatest(coalesce(p_stock, 0), 0),
    0,
    greatest(coalesce(p_min_stock_alert, 0), 0),
    true,
    coalesce(p_is_featured, false)
  )
  returning id into v_branch_product_id;

  if coalesce(p_stock, 0) > 0 then
    insert into public.stock_movements (
      branch_product_id,
      branch_id,
      product_id,
      movement_type,
      qty_change,
      qty_before,
      qty_after,
      reference_type,
      notes,
      performed_by
    )
    values (
      v_branch_product_id,
      p_branch_id,
      v_product_id,
      'opening',
      greatest(coalesce(p_stock, 0), 0),
      0,
      greatest(coalesce(p_stock, 0), 0),
      'manual',
      'Stok awal produk cabang',
      auth.uid()
    );
  end if;

  return query select v_branch_product_id, v_product_id;
end;
$$;

create or replace function public.branch_admin_update_product(
  p_branch_product_id uuid,
  p_name text,
  p_category_label text,
  p_price integer,
  p_original_price integer default null,
  p_description text default '',
  p_unit text default 'pcs',
  p_brand text default '',
  p_min_stock_alert integer default 0,
  p_is_featured boolean default false,
  p_is_active boolean default true,
  p_image_url text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
  v_product_id text;
  v_category_id uuid;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  select branch_id, product_id
  into v_branch_id, v_product_id
  from public.branch_products
  where id = p_branch_product_id;

  if v_branch_id is null or v_product_id is null then
    raise exception 'Produk cabang tidak ditemukan.';
  end if;

  if not public.is_branch_admin(v_branch_id) then
    raise exception 'Anda tidak memiliki akses ke produk cabang ini.';
  end if;

  select id
  into v_category_id
  from public.categories
  where label = p_category_label
    and is_active = true
  limit 1;

  if v_category_id is null then
    raise exception 'Kategori tidak ditemukan atau tidak aktif.';
  end if;

  update public.products
  set
    name = trim(p_name),
    price = greatest(coalesce(p_price, 0), 0),
    original_price = greatest(coalesce(p_original_price, p_price, 0), 0),
    description = coalesce(trim(p_description), ''),
    image_url = nullif(trim(coalesce(p_image_url, '')), ''),
    category_labels = array[trim(p_category_label)],
    category_id = v_category_id,
    unit = coalesce(nullif(trim(p_unit), ''), 'pcs'),
    brand = nullif(trim(p_brand), ''),
    slug = public.slugify(trim(p_name)) || '-' || substr(replace(v_product_id, '-', ''), 1, 6),
    is_active = coalesce(p_is_active, true),
    updated_at = now()
  where id = v_product_id;

  update public.branch_products
  set
    selling_price = greatest(coalesce(p_price, 0), 0),
    original_price = greatest(coalesce(p_original_price, p_price, 0), 0),
    min_stock_alert = greatest(coalesce(p_min_stock_alert, 0), 0),
    is_featured = coalesce(p_is_featured, false),
    is_active = coalesce(p_is_active, true),
    updated_at = now()
  where id = p_branch_product_id;
end;
$$;

grant execute on function public.branch_admin_create_product(uuid, text, text, integer, integer, integer, text, text, text, integer, boolean, text) to authenticated;
grant execute on function public.branch_admin_update_product(uuid, text, text, integer, integer, text, text, text, integer, boolean, boolean, text) to authenticated;
