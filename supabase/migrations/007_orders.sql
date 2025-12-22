-- 007_orders.sql
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  deal_id uuid references public.deals(id) on delete set null,

  coins_paid int not null check (coins_paid >= 0),

  phone text,
  whatsapp text,
  address text,
  city text,

  status text not null check (status in ('pending','done','cancelled')) default 'pending',

  created_at timestamptz not null default now()
);

create index if not exists idx_orders_user on public.orders(user_id);
create index if not exists idx_orders_restaurant on public.orders(restaurant_id);
create index if not exists idx_orders_created_at on public.orders(created_at);
create index if not exists idx_orders_status on public.orders(status);
