-- 004_menu_items.sql
create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,

  name text not null,
  price_rs int,
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_menu_items_restaurant on public.menu_items(restaurant_id);
create index if not exists idx_menu_items_active on public.menu_items(is_active);

drop trigger if exists trg_menu_items_touch on public.menu_items;
create trigger trg_menu_items_touch
before update on public.menu_items
for each row execute function public.touch_updated_at();
