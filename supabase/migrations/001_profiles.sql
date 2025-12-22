create extension if not exists "pgcrypto";

-- 1) Table first
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('customer','restaurant','admin')) default 'customer',
  unique_code text not null unique,
  phone text,
  whatsapp text,
  address text,
  city text,
  is_profile_complete boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_city on public.profiles(city);

-- 2) Helper function (no table dependency)
create or replace function public.generate_unique_code()
returns text
language plpgsql
as $$
declare
  code text;
begin
  code := '#' || lpad(((floor(random() * 9000) + 1000))::int::text, 4, '0');
  return code;
end;
$$;

-- 3) Trigger function
create or replace function public.set_profile_defaults()
returns trigger
language plpgsql
as $$
begin
  if new.unique_code is null or new.unique_code = '' then
    new.unique_code := public.generate_unique_code();
  end if;

  new.is_profile_complete :=
    coalesce(new.phone,'') <> ''
    and coalesce(new.whatsapp,'') <> ''
    and coalesce(new.address,'') <> ''
    and coalesce(new.city,'') <> '';

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_defaults on public.profiles;
create trigger trg_profiles_defaults
before insert or update on public.profiles
for each row
execute function public.set_profile_defaults();

-- 4) is_admin function LAST (because it reads profiles)
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
      and p.is_deleted = false
  );
$$;
