-- 002_restaurants.sql
create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete restrict,

  name text not null,
  city text not null,
  address text,
  phone text,
  whatsapp text,
  photo_url text,

  is_restricted boolean not null default false,
  is_deleted boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_restaurants_owner on public.restaurants(owner_user_id);
create index if not exists idx_restaurants_city on public.restaurants(city);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_restaurants_touch on public.restaurants;
create trigger trg_restaurants_touch
before update on public.restaurants
for each row execute function public.touch_updated_at();
