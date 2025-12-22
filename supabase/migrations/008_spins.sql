-- 008_spins.sql
create table if not exists public.spins (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  deal_text text not null,

  free_slots int not null default 0 check (free_slots >= 0),
  paid_cost_per_slot int not null default 0 check (paid_cost_per_slot >= 0),

  reg_open_at timestamptz,
  reg_close_at timestamptz,

  status text not null check (status in ('draft','published','closed','running','finished')) default 'draft',

  winner_user_id uuid references auth.users(id) on delete set null,
  is_forced_winner boolean not null default false,
  forced_user_id uuid references auth.users(id) on delete set null,

  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_spins_city on public.spins(city);
create index if not exists idx_spins_status on public.spins(status);
create index if not exists idx_spins_reg_window on public.spins(reg_open_at, reg_close_at);

drop trigger if exists trg_spins_touch on public.spins;
create trigger trg_spins_touch
before update on public.spins
for each row execute function public.touch_updated_at();
