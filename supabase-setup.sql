-- MAG-AMG Command Center: cloud storage for your private data (cost prices, orders, merchants, prices, settings).
-- Paste this whole file into Supabase > SQL Editor and press Run. Safe to run again.

create table if not exists public.cc_data (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  key        text        not null check (char_length(key) <= 60),
  value      jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, key),
  check (octet_length(value::text) < 3000000)
);

-- Turn the lock on. With the lock on and no matching rule, nobody can read or write a row.
alter table public.cc_data enable row level security;

-- Nobody who is not signed in can touch this table at all.
revoke all on public.cc_data from anon;
grant select, insert, update, delete on public.cc_data to authenticated;

-- Rules: only YOUR signed-in account, and only YOUR OWN rows.
-- If you ever change your login email, change it in the four lines below too.
drop policy if exists "owner reads"   on public.cc_data;
drop policy if exists "owner adds"    on public.cc_data;
drop policy if exists "owner changes" on public.cc_data;
drop policy if exists "owner deletes" on public.cc_data;

create policy "owner reads"   on public.cc_data for select to authenticated
  using (auth.uid() = user_id and (auth.jwt() ->> 'email') = 'monsterbaby84@gmail.com');
create policy "owner adds"    on public.cc_data for insert to authenticated
  with check (auth.uid() = user_id and (auth.jwt() ->> 'email') = 'monsterbaby84@gmail.com');
create policy "owner changes" on public.cc_data for update to authenticated
  using (auth.uid() = user_id and (auth.jwt() ->> 'email') = 'monsterbaby84@gmail.com')
  with check (auth.uid() = user_id and (auth.jwt() ->> 'email') = 'monsterbaby84@gmail.com');
create policy "owner deletes" on public.cc_data for delete to authenticated
  using (auth.uid() = user_id and (auth.jwt() ->> 'email') = 'monsterbaby84@gmail.com');

-- Keep the "last changed" time correct.
create or replace function public.cc_touch() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists cc_touch on public.cc_data;
create trigger cc_touch before update on public.cc_data for each row execute function public.cc_touch();
