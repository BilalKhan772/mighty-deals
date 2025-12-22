-- 006_wallet_ledger.sql
create table if not exists public.wallet_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  type text not null check (type in ('signup_bonus','topup','purchase_deal','spin_entry','refund','admin_mint')),
  amount int not null, -- can be + or -
  reference_type text,
  reference_id uuid,

  created_by uuid, -- who initiated (admin id / service)
  created_at timestamptz not null default now()
);

create index if not exists idx_wallet_ledger_user on public.wallet_ledger(user_id);
create index if not exists idx_wallet_ledger_created_at on public.wallet_ledger(created_at);
