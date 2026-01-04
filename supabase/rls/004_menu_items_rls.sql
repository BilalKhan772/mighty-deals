alter table public.menu_items enable row level security;

-- ✅ Public can read active menu items
-- ❌ removed restaurants exists() to avoid recursion
drop policy if exists "menu_public_select_active" on public.menu_items;
create policy "menu_public_select_active"
on public.menu_items
for select
using (is_active = true);

-- Restaurant owner can CRUD their menu
drop policy if exists "menu_owner_insert" on public.menu_items;
create policy "menu_owner_insert"
on public.menu_items
for insert
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = menu_items.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
      and r.is_restricted = false
  )
);

drop policy if exists "menu_owner_update" on public.menu_items;
create policy "menu_owner_update"
on public.menu_items
for update
using (
  exists (
    select 1 from public.restaurants r
    where r.id = menu_items.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
)
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = menu_items.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

drop policy if exists "menu_owner_delete" on public.menu_items;
create policy "menu_owner_delete"
on public.menu_items
for delete
using (
  exists (
    select 1 from public.restaurants r
    where r.id = menu_items.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

-- Admin full control
drop policy if exists "menu_admin_all" on public.menu_items;
create policy "menu_admin_all"
on public.menu_items
for all
using (public.is_admin())
with check (public.is_admin());
