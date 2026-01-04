-- 015_fix_menu_items_mighty_trigger.sql

-- Recreate function correctly
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

-- Recreate trigger (safe)
drop trigger if exists trg_menu_items_autofill_mighty on public.menu_items;

create trigger trg_menu_items_autofill_mighty
before insert or update on public.menu_items
for each row
execute function public.menu_items_autofill_mighty();
