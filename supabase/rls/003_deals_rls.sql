alter table public.deals enable row level security;

-- ✅ Public can read active deals
-- ❌ removed restaurants exists() to avoid recursion
drop policy if exists "deals_public_select_active" on public.deals;
create policy "deals_public_select_active"
on public.deals
for select
using (is_active = true);

-- Restaurant owner can CRUD only their deals (if not restricted/deleted)
drop policy if exists "deals_owner_insert" on public.deals;
create policy "deals_owner_insert"
on public.deals
for insert
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = deals.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
      and r.is_restricted = false
  )
);

drop policy if exists "deals_owner_update" on public.deals;
create policy "deals_owner_update"
on public.deals
for update
using (
  exists (
    select 1 from public.restaurants r
    where r.id = deals.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
)
with check (
  exists (
    select 1 from public.restaurants r
    where r.id = deals.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

drop policy if exists "deals_owner_delete" on public.deals;
create policy "deals_owner_delete"
on public.deals
for delete
using (
  exists (
    select 1 from public.restaurants r
    where r.id = deals.restaurant_id
      and r.owner_user_id = auth.uid()
      and r.is_deleted = false
  )
);

-- Admin full control
drop policy if exists "deals_admin_all" on public.deals;
create policy "deals_admin_all"
on public.deals
for all
using (public.is_admin())
with check (public.is_admin());
