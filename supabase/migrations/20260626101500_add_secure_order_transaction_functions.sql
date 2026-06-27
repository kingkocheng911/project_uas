create or replace function public._resolve_customer_checkout_branch_id(
  p_requested_branch_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
begin
  if p_requested_branch_id is not null then
    select b.id
    into v_branch_id
    from public.branches b
    where b.id = p_requested_branch_id
      and b.is_active = true
    limit 1;
  end if;

  if v_branch_id is not null then
    return v_branch_id;
  end if;

  if auth.uid() is not null then
    select p.default_branch_id
    into v_branch_id
    from public.profiles p
    where p.id = auth.uid()
    limit 1;

    if v_branch_id is not null then
      select b.id
      into v_branch_id
      from public.branches b
      where b.id = v_branch_id
        and b.is_active = true
      limit 1;
    end if;
  end if;

  if v_branch_id is not null then
    return v_branch_id;
  end if;

  select b.id
  into v_branch_id
  from public.branches b
  where b.is_active = true
  order by b.name
  limit 1;

  return v_branch_id;
end;
$$;

create or replace function public._branch_admin_can_transition_order(
  p_order_type text,
  p_current_status text,
  p_next_status text
)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_current_status = p_next_status then
    return true;
  end if;

  if p_current_status in ('completed', 'cancelled') then
    return false;
  end if;

  if p_order_type = 'pickup' then
    return (p_current_status = 'pending' and p_next_status in ('confirmed', 'cancelled'))
      or (p_current_status = 'confirmed' and p_next_status in ('processing', 'cancelled'))
      or (p_current_status = 'processing' and p_next_status in ('ready_pickup', 'cancelled'))
      or (p_current_status = 'ready_pickup' and p_next_status = 'completed');
  end if;

  return (p_current_status = 'pending' and p_next_status in ('confirmed', 'cancelled'))
    or (p_current_status = 'confirmed' and p_next_status in ('processing', 'cancelled'))
    or (p_current_status = 'processing' and p_next_status in ('out_for_delivery', 'cancelled'))
    or (p_current_status = 'out_for_delivery' and p_next_status = 'completed');
end;
$$;

create or replace function public.customer_place_order(
  p_items jsonb,
  p_payment_method_code text,
  p_order_type text default 'delivery',
  p_requested_branch_id uuid default null,
  p_address_id uuid default null,
  p_delivery_label text default null,
  p_delivery_address text default null,
  p_notes text default null
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
  branch_id uuid,
  branch_name text,
  wallet_balance integer
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
  v_subtotal integer := 0;
  v_grand_total integer := 0;
  v_wallet_balance integer := 0;
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
  v_grand_total := v_subtotal + v_delivery_fee;
  v_payment_status := case when v_payment_method_code = 'wallet' then 'paid' else 'unpaid' end;
  v_order_status := case
    when v_payment_method_code = 'wallet' then 'processing'
    else 'pending'
  end;

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
    grand_total,
    notes
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
    0,
    v_delivery_fee,
    v_grand_total,
    nullif(trim(coalesce(p_notes, '')), '')
  )
  returning id, public.orders.order_no, public.orders.placed_at
  into v_order_id, v_order_no, v_placed_at;

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
    v_branch_id,
    v_branch_name,
    coalesce(v_wallet_balance, 0);
end;
$$;

create or replace function public.customer_pay_order(
  p_order_no text
)
returns table(
  order_id uuid,
  order_no text,
  order_status text,
  payment_status text,
  order_type text,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_order public.orders%rowtype;
begin
  if v_user_id is null then
    raise exception 'User belum login.';
  end if;

  select *
  into v_order
  from public.orders
  where order_no = nullif(trim(coalesce(p_order_no, '')), '')
    and user_id = v_user_id
  limit 1
  for update;

  if v_order.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_order.order_status <> 'pending' or v_order.payment_status <> 'unpaid' then
    raise exception 'Pesanan ini tidak dapat dibayar lagi dari aplikasi.';
  end if;

  update public.orders
  set
    payment_status = 'paid',
    order_status = case when v_order.order_type = 'pickup' then 'ready_pickup' else 'processing' end,
    updated_at = now()
  where id = v_order.id
  returning
    public.orders.id,
    public.orders.order_no,
    public.orders.order_status,
    public.orders.payment_status,
    public.orders.order_type,
    public.orders.completed_at
  into order_id, order_no, order_status, payment_status, order_type, completed_at;

  return next;
end;
$$;

create or replace function public.customer_cancel_order(
  p_order_no text
)
returns table(
  order_id uuid,
  order_no text,
  order_status text,
  payment_status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_order public.orders%rowtype;
  v_item record;
  v_stock_before integer;
  v_stock_after integer;
begin
  if v_user_id is null then
    raise exception 'User belum login.';
  end if;

  select *
  into v_order
  from public.orders
  where order_no = nullif(trim(coalesce(p_order_no, '')), '')
    and user_id = v_user_id
  limit 1
  for update;

  if v_order.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_order.order_status <> 'pending' or v_order.payment_status <> 'unpaid' then
    raise exception 'Pesanan ini tidak dapat dibatalkan lagi dari aplikasi.';
  end if;

  for v_item in
    select oi.branch_product_id, oi.product_id, oi.qty
    from public.order_items oi
    where oi.order_id = v_order.id
      and oi.branch_product_id is not null
  loop
    select bp.stock_on_hand
    into v_stock_before
    from public.branch_products bp
    where bp.id = v_item.branch_product_id
    for update;

    v_stock_after := coalesce(v_stock_before, 0) + coalesce(v_item.qty, 0);

    update public.branch_products
    set
      stock_on_hand = v_stock_after,
      updated_at = now()
    where id = v_item.branch_product_id;

    update public.products
    set
      stock = v_stock_after,
      updated_at = now()
    where id = v_item.product_id;

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
      v_item.branch_product_id,
      v_order.branch_id,
      v_item.product_id,
      'cancel_release',
      coalesce(v_item.qty, 0),
      coalesce(v_stock_before, 0),
      v_stock_after,
      'order',
      v_order.id,
      'Pembatalan pesanan customer',
      v_user_id
    );
  end loop;

  update public.orders
  set
    order_status = 'cancelled',
    payment_status = 'failed',
    updated_at = now()
  where id = v_order.id
  returning
    public.orders.id,
    public.orders.order_no,
    public.orders.order_status,
    public.orders.payment_status
  into order_id, order_no, order_status, payment_status;

  return next;
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

  return next;
end;
$$;

grant execute on function public.customer_place_order(jsonb, text, text, uuid, uuid, text, text, text) to authenticated;
grant execute on function public.customer_pay_order(text) to authenticated;
grant execute on function public.customer_cancel_order(text) to authenticated;
grant execute on function public.branch_admin_update_order_status(uuid, text, text, text) to authenticated;
