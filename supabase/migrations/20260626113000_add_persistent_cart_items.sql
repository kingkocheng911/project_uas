create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  branch_product_id uuid not null references public.branch_products (id) on delete cascade,
  quantity integer not null default 1
    check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists cart_items_user_branch_product_key
on public.cart_items (user_id, branch_product_id);

create index if not exists cart_items_user_id_idx
on public.cart_items (user_id);

create or replace function public.enforce_single_branch_cart()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_branch_id uuid;
  existing_branch_id uuid;
begin
  select branch_id
  into new_branch_id
  from public.branch_products
  where id = new.branch_product_id;

  if new_branch_id is null then
    raise exception 'Produk cabang untuk keranjang tidak ditemukan.';
  end if;

  select bp.branch_id
  into existing_branch_id
  from public.cart_items ci
  join public.branch_products bp on bp.id = ci.branch_product_id
  where ci.user_id = new.user_id
    and ci.id <> coalesce(
      new.id,
      '00000000-0000-0000-0000-000000000000'::uuid
    )
  limit 1;

  if existing_branch_id is not null and existing_branch_id <> new_branch_id then
    raise exception 'Keranjang hanya dapat berisi produk dari satu cabang.';
  end if;

  return new;
end;
$$;

drop trigger if exists cart_items_enforce_single_branch on public.cart_items;
create trigger cart_items_enforce_single_branch
before insert or update of user_id, branch_product_id
on public.cart_items
for each row execute function public.enforce_single_branch_cart();

drop trigger if exists set_cart_items_updated_at on public.cart_items;
create trigger set_cart_items_updated_at
before update on public.cart_items
for each row execute procedure public.set_updated_at();

alter table public.cart_items enable row level security;

drop policy if exists "users read own cart items" on public.cart_items;
create policy "users read own cart items"
on public.cart_items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users insert own cart items" on public.cart_items;
create policy "users insert own cart items"
on public.cart_items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users update own cart items" on public.cart_items;
create policy "users update own cart items"
on public.cart_items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users delete own cart items" on public.cart_items;
create policy "users delete own cart items"
on public.cart_items
for delete
to authenticated
using (auth.uid() = user_id);
