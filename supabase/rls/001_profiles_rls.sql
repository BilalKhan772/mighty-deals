-- 001_profiles_rls.sql (FIXED)
alter table public.profiles enable row level security;

-- Read own profile
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (id = auth.uid() and is_deleted = false);

-- Admin can read all
drop policy if exists "profiles_admin_select_all" on public.profiles;
create policy "profiles_admin_select_all"
on public.profiles
for select
using (public.is_admin());

-- ✅ IMPORTANT: Block direct client updates completely
-- (Profile updates MUST go via RPC public.update_my_profile)
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (false);

-- Admin can update all
drop policy if exists "profiles_admin_update_all" on public.profiles;
create policy "profiles_admin_update_all"
on public.profiles
for update
using (public.is_admin())
with check (public.is_admin());
