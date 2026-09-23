-- 0010_famrec_sync.sql
-- Sync store for famrec (ttrng3.github.io/famrec) — the personal and family
-- record book. It lives in this migration chain because it is the same
-- database; one database, one chain. It touches nothing 0001–0009 created.
--
-- Design: local-first. The browser keeps the authoritative copy and this table
-- is a convergence mirror — one row per signed-in person, holding that
-- person's whole document. Merging happens on the client by record id, so two
-- devices that both edited between syncs each survive. Deletions travel as
-- tombstones inside the document rather than as row deletes.
--
-- Nobody can read anybody else's row: every policy below is scoped to auth.uid().

create table if not exists public.famrec_state (
  user_id     uuid        primary key references auth.users(id) on delete cascade,
  doc         jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  device      text
);

comment on table public.famrec_state is
  'famrec: one document per user. Local-first; this is the convergence mirror.';

alter table public.famrec_state enable row level security;

drop policy if exists famrec_state_select on public.famrec_state;
drop policy if exists famrec_state_insert on public.famrec_state;
drop policy if exists famrec_state_update on public.famrec_state;
drop policy if exists famrec_state_delete on public.famrec_state;

create policy famrec_state_select on public.famrec_state
  for select using (auth.uid() = user_id);
create policy famrec_state_insert on public.famrec_state
  for insert with check (auth.uid() = user_id);
create policy famrec_state_update on public.famrec_state
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy famrec_state_delete on public.famrec_state
  for delete using (auth.uid() = user_id);

-- updated_at is set by the database, never by the client: a phone with a wrong
-- clock must not win a comparison it should have lost.
create or replace function public.famrec_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists famrec_state_touch on public.famrec_state;
create trigger famrec_state_touch
  before insert or update on public.famrec_state
  for each row execute function public.famrec_touch();
