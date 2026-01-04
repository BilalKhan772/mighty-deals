-- 014_menu_items_add_price_mighty.sql

alter table public.menu_items
  add column if not exists price_mighty int not null default 0;

create index if not exists idx_menu_items_restaurant_active
  on public.menu_items(restaurant_id, is_active);

-- Optional: auto-calc mighty if price_rs exists and price_mighty = 0
-- 1 Mighty = 3 Rs  (change if needed)
create or replace function public.calc_mighty_from_rs(rs int)
returns int
language sql
immutable
as $$
  select case
    when rs is null or rs <= 0 then 0
    else ((rs + 2) / 3)
  end;
$$;

drop trigger if exists trg_menu_items_autofill_mighty on public.menu_items;

create trigger trg_menu_items_autofill_mighty
before insert or update on public.menu_items
for each row
execute function public.menu_items_autofill_mighty();

-- Helper trigger fn
create or replace function public.menu_items_autofill_mighty()
returns trigger
language plpgsql
as $$
begin
  if (new.price_mighty is null or new.price_mighty <= 0) then
    new.price_mighty := public.calc_mighty_from_rs(new.price_rs);
  end if;
  return new;
end;
$$;
