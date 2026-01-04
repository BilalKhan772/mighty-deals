-- 012_orders_menu_support.sql

alter table public.orders
  add column if not exists menu_item_id uuid references public.menu_items(id) on delete set null;

-- Ensure exactly one of deal_id/menu_item_id is set
alter table public.orders
  drop constraint if exists orders_one_item_only;

alter table public.orders
  add constraint orders_one_item_only check (
    (deal_id is not null and menu_item_id is null)
    or
    (deal_id is null and menu_item_id is not null)
  );

create index if not exists idx_orders_menu_item_id on public.orders(menu_item_id);
