-- 007_orders.sql

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,

  -- one of these two will be set
  deal_id uuid references public.deals(id) on delete set null,
  menu_item_id uuid references public.menu_items(id) on delete set null,

  coins_paid int not null check (coins_paid >= 0),

  phone text,
  whatsapp text,
  address text,
  city text,

  status text not null check (status in ('pending','done','cancelled')) default 'pending',

  created_at timestamptz not null default now()
);

-- ✅ In case table already existed before this migration was updated:
alter table public.orders
  add column if not exists menu_item_id uuid references public.menu_items(id) on delete set null;

-- ✅ ensure only one item is chosen (deal OR menu item)
alter table public.orders
  drop constraint if exists orders_exactly_one_item;

alter table public.orders
  add constraint orders_exactly_one_item
  check (
    (deal_id is null and menu_item_id is not null)
    or
    (deal_id is not null and menu_item_id is null)
  );

-- indexes
create index if not exists idx_orders_user on public.orders(user_id);
create index if not exists idx_orders_restaurant on public.orders(restaurant_id);
create index if not exists idx_orders_deal_id on public.orders(deal_id);
create index if not exists idx_orders_menu_item_id on public.orders(menu_item_id);
create index if not exists idx_orders_created_at on public.orders(created_at);
create index if not exists idx_orders_status on public.orders(status);
