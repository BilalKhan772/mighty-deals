-- 009_spin_entries_rls.sql
alter table public.spin_entries enable row level security;

-- Public can read entries for a spin (optional; useful for participants count)
drop policy if exists "spin_entries_public_select" on public.spin_entries;
create policy "spin_entries_public_select"
on public.spin_entries
for select
using (
  exists (
    select 1 from public.spins s
    where s.id = spin_entries.spin_id
      and s.status in ('published','running','finished','closed')
  )
);

-- User can read own entries
drop policy if exists "spin_entries_select_own" on public.spin_entries;
create policy "spin_entries_select_own"
on public.spin_entries
for select
using (user_id = auth.uid());

-- Block client inserts (paid/free registration should be via edge functions)
drop policy if exists "spin_entries_no_client_insert" on public.spin_entries;
create policy "spin_entries_no_client_insert"
on public.spin_entries
for insert
with check (false);

-- Admin can read all entries
drop policy if exists "spin_entries_admin_select_all" on public.spin_entries;
create policy "spin_entries_admin_select_all"
on public.spin_entries
for select
using (public.is_admin());
