-- 010_wallet_signup_bonus.sql
-- Purpose: Auto create wallet + give signup bonus (30 Mighty)

create or replace function public.ensure_wallet_and_signup_bonus()
returns trigger
language plpgsql
security definer
as $$
begin
  -- 1) ensure wallet row
  insert into public.wallets(user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  -- 2) give signup bonus only once
  if not exists (
    select 1 from public.wallet_ledger
    where user_id = new.id
      and type = 'signup_bonus'
  ) then
    insert into public.wallet_ledger(
      user_id,
      type,
      amount,
      reference_type
    )
    values (
      new.id,
      'signup_bonus',
      30,
      'system'
    );

    update public.wallets
    set balance = balance + 30,
        updated_at = now()
    where user_id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_profiles_wallet_bonus on public.profiles;
create trigger trg_profiles_wallet_bonus
after insert on public.profiles
for each row
execute function public.ensure_wallet_and_signup_bonus();
