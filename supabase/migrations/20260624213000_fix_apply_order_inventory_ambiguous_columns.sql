create or replace function public.apply_order_inventory(
  p_order_id uuid,
  p_action text default 'deduct'
)
returns table(
  applied boolean,
  stock_deducted_at timestamptz,
  stock_restored_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_item record;
  v_branch_product_id uuid;
  v_qty_before integer;
  v_qty_after integer;
  v_action text := lower(trim(coalesce(p_action, 'deduct')));
  v_result_stock_deducted_at timestamptz;
  v_result_stock_restored_at timestamptz;
begin
  if auth.uid() is null and current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'User belum login.';
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if auth.uid() is not null and not (
    v_order.user_id = auth.uid()
    or public.is_superadmin()
    or (v_order.branch_id is not null and public.is_branch_admin(v_order.branch_id))
  ) then
    raise exception 'Anda tidak memiliki akses ke pesanan ini.';
  end if;

  if v_action not in ('deduct', 'restore') then
    raise exception 'Aksi inventory tidak valid.';
  end if;

  if v_action = 'deduct' and v_order.stock_deducted_at is not null and v_order.stock_restored_at is null then
    return query
    select false, v_order.stock_deducted_at, v_order.stock_restored_at;
    return;
  end if;

  if v_action = 'restore' and (
    v_order.stock_deducted_at is null or v_order.stock_restored_at is not null
  ) then
    return query
    select false, v_order.stock_deducted_at, v_order.stock_restored_at;
    return;
  end if;

  for v_item in
    select
      oi.id as order_item_id,
      oi.product_id,
      oi.product_name,
      greatest(coalesce(oi.qty, 0), 0) as qty,
      oi.branch_product_id
    from public.order_items oi
    where oi.order_id = v_order.id
  loop
    if v_item.qty <= 0 then
      continue;
    end if;

    v_branch_product_id := v_item.branch_product_id;

    if v_branch_product_id is null then
      select bp.id
      into v_branch_product_id
      from public.branch_products bp
      where bp.branch_id = v_order.branch_id
        and bp.product_id = v_item.product_id
      limit 1;

      if v_branch_product_id is not null then
        update public.order_items
        set branch_product_id = v_branch_product_id
        where id = v_item.order_item_id
          and branch_product_id is null;
      end if;
    end if;

    if v_branch_product_id is null then
      raise exception 'Produk cabang untuk item pesanan "%" tidak ditemukan.', v_item.product_name;
    end if;

    select stock_on_hand
    into v_qty_before
    from public.branch_products
    where id = v_branch_product_id
    for update;

    if v_qty_before is null then
      raise exception 'Stok cabang untuk item pesanan "%" tidak ditemukan.', v_item.product_name;
    end if;

    if v_action = 'deduct' then
      if v_qty_before < v_item.qty then
        raise exception 'Stok "%" tidak cukup. Tersisa %, diminta %.', v_item.product_name, v_qty_before, v_item.qty;
      end if;
      v_qty_after := v_qty_before - v_item.qty;
    else
      v_qty_after := v_qty_before + v_item.qty;
    end if;

    update public.branch_products
    set
      stock_on_hand = v_qty_after,
      updated_at = now()
    where id = v_branch_product_id;

    update public.products
    set
      stock = v_qty_after,
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
      notes,
      performed_by
    )
    values (
      v_branch_product_id,
      v_order.branch_id,
      v_item.product_id,
      case
        when v_action = 'deduct' then 'sale'
        else 'return'
      end,
      case
        when v_action = 'deduct' then -v_item.qty
        else v_item.qty
      end,
      v_qty_before,
      v_qty_after,
      'order',
      case
        when v_action = 'deduct' then 'Order ' || coalesce(v_order.order_no, v_order.id::text)
        else 'Pembatalan order ' || coalesce(v_order.order_no, v_order.id::text)
      end,
      coalesce(auth.uid(), v_order.user_id)
    );
  end loop;

  update public.orders
  set
    stock_deducted_at = case
      when v_action = 'deduct' then coalesce(public.orders.stock_deducted_at, now())
      else public.orders.stock_deducted_at
    end,
    stock_restored_at = case
      when v_action = 'deduct' then null
      else coalesce(public.orders.stock_restored_at, now())
    end
  where id = v_order.id
  returning public.orders.stock_deducted_at, public.orders.stock_restored_at
  into v_result_stock_deducted_at, v_result_stock_restored_at;

  return query
  select true, v_result_stock_deducted_at, v_result_stock_restored_at;
end;
$$;
