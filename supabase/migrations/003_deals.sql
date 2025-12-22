-- 003_deals.sql
create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,

  city text not null,
  title text not null,
  description text,
  category text not null default 'All',
  price_rs int,
  price_mighty int not null check (price_mighty >= 0),
  tag text,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_deals_restaurant on public.deals(restaurant_id);
create index if not exists idx_deals_city on public.deals(city);
create index if not exists idx_deals_category on public.deals(category);
create index if not exists idx_deals_created_at on public.deals(created_at);

drop trigger if exists trg_deals_touch on public.deals;
create trigger trg_deals_touch
before update on public.deals
for each row execute function public.touch_updated_at();
