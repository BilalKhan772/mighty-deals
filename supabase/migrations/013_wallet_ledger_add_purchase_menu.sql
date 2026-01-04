-- 013_wallet_ledger_add_purchase_menu.sql

alter table public.wallet_ledger
  drop constraint if exists wallet_ledger_type_check;

alter table public.wallet_ledger
  add constraint wallet_ledger_type_check
  check (type in (
    'signup_bonus',
    'topup',
    'purchase_deal',
    'purchase_menu',
    'spin_entry',
    'refund',
    'admin_mint'
  ));
