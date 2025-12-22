-- 002_restaurants_rls.sql
alter table public.restaurants enable row level security;

-- Everyone can read active restaurants (for customer app)
drop policy if exists "restaurants_public_select" on public.restaurants;
create policy "restaurants_public_select"
on public.restaurants
for select
using (is_deleted = false and is_restricted = false);

-- Restaurant owner can update own restaurant
drop policy if exists "restaurants_owner_update" on public.restaurants;
create policy "restaurants_owner_update"
on public.restaurants
for update
using (owner_user_id = auth.uid() and is_deleted = false)
with check (owner_user_id = auth.uid() and is_deleted = false);

-- Admin full control
drop policy if exists "restaurants_admin_all" on public.restaurants;
create policy "restaurants_admin_all"
on public.restaurants
for all
using (public.is_admin())
with check (public.is_admin());
