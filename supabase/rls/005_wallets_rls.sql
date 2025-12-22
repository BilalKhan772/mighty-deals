-- 005_wallets_rls.sql
alter table public.wallets enable row level security;

-- User can read own wallet
drop policy if exists "wallets_select_own" on public.wallets;
create policy "wallets_select_own"
on public.wallets
for select
using (user_id = auth.uid());

-- Block direct updates from client (coins must be via Edge Functions / admin)
drop policy if exists "wallets_no_client_update" on public.wallets;
create policy "wallets_no_client_update"
on public.wallets
for update
using (false);

-- Admin can select all wallets
drop policy if exists "wallets_admin_select_all" on public.wallets;
create policy "wallets_admin_select_all"
on public.wallets
for select
using (public.is_admin());
