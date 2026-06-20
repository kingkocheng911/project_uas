create or replace function public.slugify(source text)
returns text
language sql
immutable
as $$
  select trim(both '-' from lower(regexp_replace(coalesce(source, ''), '[^a-zA-Z0-9]+', '-', 'g')));
$$;

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
  p_is_featured boolean default false
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
    null,
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
  p_is_active boolean default true
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

create or replace function public.branch_admin_adjust_stock(
  p_branch_product_id uuid,
  p_qty_change integer,
  p_movement_type text,
  p_notes text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
  v_product_id text;
  v_qty_before integer;
  v_qty_after integer;
begin
  if auth.uid() is null then
    raise exception 'User belum login.';
  end if;

  if coalesce(p_qty_change, 0) = 0 then
    raise exception 'Perubahan stok tidak boleh 0.';
  end if;

  if p_movement_type not in ('purchase', 'adjustment_in', 'adjustment_out', 'return') then
    raise exception 'Jenis mutasi stok tidak valid.';
  end if;

  select branch_id, product_id, stock_on_hand
  into v_branch_id, v_product_id, v_qty_before
  from public.branch_products
  where id = p_branch_product_id
  for update;

  if v_branch_id is null then
    raise exception 'Produk cabang tidak ditemukan.';
  end if;

  if not public.is_branch_admin(v_branch_id) then
    raise exception 'Anda tidak memiliki akses ke stok cabang ini.';
  end if;

  v_qty_after := greatest(v_qty_before + p_qty_change, 0);

  update public.branch_products
  set
    stock_on_hand = v_qty_after,
    updated_at = now()
  where id = p_branch_product_id;

  update public.products
  set
    stock = v_qty_after,
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
    notes,
    performed_by
  )
  values (
    p_branch_product_id,
    v_branch_id,
    v_product_id,
    p_movement_type,
    p_qty_change,
    v_qty_before,
    v_qty_after,
    'manual',
    nullif(trim(coalesce(p_notes, '')), ''),
    auth.uid()
  );

  return v_qty_after;
end;
$$;

create or replace function public.notify_customer_order_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title text;
  v_message text;
begin
  if tg_op = 'INSERT' then
    v_title := 'Pesanan berhasil dibuat';
    v_message := 'Pesanan ' || coalesce(new.order_no, '-') || ' sudah masuk ke cabang dan menunggu proses admin.';
  elsif tg_op = 'UPDATE' then
    if new.order_status = old.order_status and new.payment_status = old.payment_status then
      return new;
    end if;

    v_title := 'Status pesanan diperbarui';
    v_message := 'Pesanan ' || coalesce(new.order_no, '-') || ' sekarang berstatus ' || coalesce(new.order_status, '-') || '.';
  else
    return new;
  end if;

  insert into public.notifications (
    user_id,
    branch_id,
    type,
    title,
    message,
    data,
    sent_at
  )
  values (
    new.user_id,
    new.branch_id,
    'order',
    v_title,
    v_message,
    jsonb_build_object(
      'order_id', new.id,
      'order_no', new.order_no,
      'order_status', new.order_status,
      'payment_status', new.payment_status
    ),
    now()
  );

  return new;
end;
$$;

drop trigger if exists notify_customer_on_order_insert on public.orders;
create trigger notify_customer_on_order_insert
after insert on public.orders
for each row execute procedure public.notify_customer_order_change();

drop trigger if exists notify_customer_on_order_update on public.orders;
create trigger notify_customer_on_order_update
after update of order_status, payment_status on public.orders
for each row execute procedure public.notify_customer_order_change();

grant execute on function public.branch_admin_create_product(uuid, text, text, integer, integer, integer, text, text, text, integer, boolean) to authenticated;
grant execute on function public.branch_admin_update_product(uuid, text, text, integer, integer, text, text, text, integer, boolean, boolean) to authenticated;
grant execute on function public.branch_admin_adjust_stock(uuid, integer, text, text) to authenticated;
