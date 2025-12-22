-- 007_orders_rls.sql
alter table public.orders enable row level security;

-- User can read own orders
drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own"
on public.orders
for select
using (user_id = auth.uid());

-- Restaurant owner can read orders for their restaurant
drop policy if exists "orders_restaurant_owner_select" on public.orders;
create policy "orders_restaurant_owner_select"
on public.orders
for select
using (
  exists (
    select 1 from public.restaurants r
    where r.id = orders.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

-- Block client inserts (must be via Edge Function / admin)
drop policy if exists "orders_no_client_insert" on public.orders;
create policy "orders_no_client_insert"
on public.orders
for insert
with check (false);

-- Restaurant owner can update status (pending/done/cancelled)
drop policy if exists "orders_restaurant_owner_update_status" on public.orders;
create policy "orders_restaurant_owner_update_status"
on public.orders
for update
using (
  exists (
    select 1 from public.restaurants r
    where r.id = orders.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
)
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = orders.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

-- Admin full control
drop policy if exists "orders_admin_all" on public.orders;
create policy "orders_admin_all"
on public.orders
for all
using (public.is_admin())
with check (public.is_admin());
