-- 008_spins_rls.sql
alter table public.spins enable row level security;

-- Public can read published/running/finished spins
drop policy if exists "spins_public_select" on public.spins;
create policy "spins_public_select"
on public.spins
for select
using (status in ('published','running','finished','closed'));

-- Admin can CRUD spins
drop policy if exists "spins_admin_all" on public.spins;
create policy "spins_admin_all"
on public.spins
for all
using (public.is_admin())
with check (public.is_admin());
