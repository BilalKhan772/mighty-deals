-- 005_wallets.sql
create table if not exists public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance int not null default 0 check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_wallets_balance on public.wallets(balance);

drop trigger if exists trg_wallets_touch on public.wallets;
create trigger trg_wallets_touch
before update on public.wallets
for each row execute function public.touch_updated_at();
