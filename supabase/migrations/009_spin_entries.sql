-- 009_spin_entries.sql
create table if not exists public.spin_entries (
  id uuid primary key default gen_random_uuid(),
  spin_id uuid not null references public.spins(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,

  entry_type text not null check (entry_type in ('free','paid')),
  created_at timestamptz not null default now()
);

create index if not exists idx_spin_entries_spin on public.spin_entries(spin_id);
create index if not exists idx_spin_entries_user on public.spin_entries(user_id);
create index if not exists idx_spin_entries_created_at on public.spin_entries(created_at);

-- Optional: prevent multiple FREE entries per user per spin
create unique index if not exists uniq_spin_free_entry
on public.spin_entries(spin_id, user_id)
where entry_type = 'free';
