-- 006_wallet_ledger_rls.sql
alter table public.wallet_ledger enable row level security;

-- User can read own ledger
drop policy if exists "ledger_select_own" on public.wallet_ledger;
create policy "ledger_select_own"
on public.wallet_ledger
for select
using (user_id = auth.uid());

-- No client inserts/updates/deletes (Edge Functions / admin only)
drop policy if exists "ledger_no_client_insert" on public.wallet_ledger;
create policy "ledger_no_client_insert"
on public.wallet_ledger
for insert
with check (false);

drop policy if exists "ledger_no_client_update" on public.wallet_ledger;
create policy "ledger_no_client_update"
on public.wallet_ledger
for update
using (false);

drop policy if exists "ledger_no_client_delete" on public.wallet_ledger;
create policy "ledger_no_client_delete"
on public.wallet_ledger
for delete
using (false);

-- Admin can read all ledger rows
drop policy if exists "ledger_admin_select_all" on public.wallet_ledger;
create policy "ledger_admin_select_all"
on public.wallet_ledger
for select
using (public.is_admin());
