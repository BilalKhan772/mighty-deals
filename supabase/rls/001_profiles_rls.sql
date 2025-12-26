-- Enable RLS
alter table public.profiles enable row level security;

-- Read own profile
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (id = auth.uid() and is_deleted = false);

-- Admin read all
drop policy if exists "profiles_admin_select_all" on public.profiles;
create policy "profiles_admin_select_all"
on public.profiles
for select
using (public.is_admin());

-- ✅ User can update ONLY own profile
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (id = auth.uid() and is_deleted = false)
with check (id = auth.uid() and is_deleted = false);

-- Admin update all
drop policy if exists "profiles_admin_update_all" on public.profiles;
create policy "profiles_admin_update_all"
on public.profiles
for update
using (public.is_admin())
with check (public.is_admin());
