alter table public.profiles
  add column if not exists wallet_balance integer not null default 0;
update public.profiles
set wallet_balance = 0
where wallet_balance is null;
