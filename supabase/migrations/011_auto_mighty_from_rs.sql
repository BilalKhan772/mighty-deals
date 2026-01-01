-- 011_auto_mighty_from_rs.sql (run in SQL editor)

-- 1) Add mighty column in menu_items
alter table public.menu_items
add column if not exists price_mighty int4;

alter table public.menu_items
drop constraint if exists menu_items_price_mighty_check;

alter table public.menu_items
add constraint menu_items_price_mighty_check check (price_mighty is null or price_mighty >= 0);


-- 2) Utility function: ceil(rs/3)
create or replace function public.calc_mighty_from_rs(rs int)
returns int
language sql
immutable
as $$
  select case
    when rs is null or rs <= 0 then null
    else ceil(rs::numeric / 3)::int
  end;
$$;


-- 3) Deals: if price_rs provided => auto set mighty, else keep manual mighty
create or replace function public.deals_set_mighty_from_rs()
returns trigger
language plpgsql
as $$
declare
  computed int;
begin
  computed := public.calc_mighty_from_rs(new.price_rs);

  if computed is not null then
    new.price_mighty := computed;
  else
    -- keep existing manual mighty (mighty-only deals)
    if new.price_mighty is null then
      new.price_mighty := 0;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_deals_set_mighty_from_rs on public.deals;

create trigger trg_deals_set_mighty_from_rs
before insert or update of price_rs on public.deals
for each row
execute function public.deals_set_mighty_from_rs();


-- 4) Menu: always compute mighty from rs
create or replace function public.menu_set_mighty_from_rs()
returns trigger
language plpgsql
as $$
declare
  computed int;
begin
  computed := public.calc_mighty_from_rs(new.price_rs);
  new.price_mighty := coalesce(computed, 0);
  return new;
end;
$$;

drop trigger if exists trg_menu_set_mighty_from_rs on public.menu_items;

create trigger trg_menu_set_mighty_from_rs
before insert or update of price_rs on public.menu_items
for each row
execute function public.menu_set_mighty_from_rs();


-- 5) Backfill old menu rows
update public.menu_items
set price_mighty = coalesce(public.calc_mighty_from_rs(price_rs), 0)
where price_mighty is null;
