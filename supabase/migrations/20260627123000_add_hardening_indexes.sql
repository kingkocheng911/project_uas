create index if not exists orders_branch_placed_at_idx
on public.orders (branch_id, placed_at desc);

create index if not exists orders_user_placed_at_idx
on public.orders (user_id, placed_at desc);

create index if not exists orders_status_branch_placed_at_idx
on public.orders (order_status, branch_id, placed_at desc);

create index if not exists orders_payment_status_placed_at_idx
on public.orders (payment_status, placed_at desc);

create index if not exists branch_products_branch_active_updated_idx
on public.branch_products (branch_id, is_active, updated_at desc);

create index if not exists branch_products_branch_stock_idx
on public.branch_products (branch_id, stock_on_hand, min_stock_alert);

create index if not exists stock_movements_branch_created_at_idx
on public.stock_movements (branch_id, created_at desc);

create index if not exists stock_movements_branch_product_created_at_idx
on public.stock_movements (branch_product_id, created_at desc);

create index if not exists order_items_order_id_idx
on public.order_items (order_id);

create index if not exists order_items_product_id_idx
on public.order_items (product_id);

create index if not exists branch_admins_user_active_primary_idx
on public.branch_admins (user_id, is_active, is_primary desc);

create index if not exists promotions_branch_active_schedule_idx
on public.promotions (branch_id, is_active, start_at desc, end_at desc);

create index if not exists notifications_user_created_at_idx
on public.notifications (user_id, created_at desc);

create index if not exists wallet_topups_user_status_created_at_idx
on public.wallet_topups (user_id, status, created_at desc);

create index if not exists cart_items_user_created_at_idx
on public.cart_items (user_id, created_at desc);

create index if not exists reward_transactions_order_id_idx
on public.reward_transactions (order_id);
