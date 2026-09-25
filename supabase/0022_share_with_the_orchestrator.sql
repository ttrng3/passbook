-- 0022_share_with_the_orchestrator.sql — a relative may hand their book to
-- the person who invited them, read-only, and take it back by deleting it.
--
-- SECOND OVERRULE, RECORDED. 0021 already carries the first: the council of
-- 2026-09-24 ruled Passbook a single-user personal tool, and Ty restored the
-- family invite knowing that. The line that survived 0021 was narrower and
-- was written down: *sync is Ty's own devices only; relatives use hand-off
-- files, because holding a relative's records on a server Ty operates is
-- third-party health data crossing a border, and that is the unanswered
-- counsel question.* On 2026-09-25, shown that sentence, Ty ruled to build
-- this anyway: "làm đi".
--
-- So this file does not pretend to answer the question. It narrows it:
--
--   * Nothing is shared unless the sharer switches it on. Default off, and
--     off is the state of a book nobody has touched.
--   * The recipient is NOT chosen by the page. It is read server-side from
--     family_invites.invited_by -- the person who let you in is the only
--     person you can hand your book to. A compromised page cannot redirect
--     a copy to anyone else, because the client never names the recipient.
--   * The recipient can read and can never write. There is no policy on this
--     table that lets anybody modify a row they do not own.
--   * Revoking is a DELETE, not a flag. When somebody stops sharing, the copy
--     stops existing rather than being hidden.
--   * The copy excludes anything already marked `local` -- records a third
--     person handed the sharer. Somebody else's records do not travel one
--     more hop. That is enforced by syncable() on the client, as it already
--     is for the sync document, and it is the reason this is a separate
--     table rather than a widened read on passbook_state.
--
-- What it still is, plainly: another person's medical record, in a database
-- in Singapore, readable by an account that is not theirs. The switch and the
-- delete are real controls; the border is not moved by either.
--
-- Reversible, and revocation is total:
--   drop table public.passbook_shares;
--   drop function public.my_orchestrator();

-- Who invited me. No argument, so it cannot be used to ask who invited
-- somebody else -- it only ever answers for the caller's own token.
create or replace function public.my_orchestrator()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select invited_by
    from public.family_invites
   where lower(email) = lower(auth.jwt() ->> 'email')
   limit 1
$$;

revoke all on function public.my_orchestrator() from public;
grant execute on function public.my_orchestrator() to authenticated;

create table if not exists public.passbook_shares (
  user_id      uuid        primary key references auth.users(id) on delete cascade,
  shared_with  uuid        not null references auth.users(id) on delete cascade,
  shared_email text        not null,
  label        text,
  doc          jsonb       not null default '{}'::jsonb,
  updated_at   timestamptz not null default now()
);

comment on table public.passbook_shares is
  'Passbook: a read-only copy one person chose to give the person who invited them. One row per sharer. Deleting the row is how sharing is revoked.';

create index if not exists passbook_shares_to on public.passbook_shares (shared_with);

alter table public.passbook_shares enable row level security;

-- The sharer owns their row entirely: writes it, reads it back, deletes it.
-- The WITH CHECK is where the recipient is pinned. shared_with must equal
-- what the database itself says about who invited this caller, so the page
-- cannot aim a copy anywhere, and shared_email must be the caller's own
-- address, so a row cannot be labelled as somebody else's book.
drop policy if exists passbook_shares_own on public.passbook_shares;
create policy passbook_shares_own on public.passbook_shares
  for all to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and shared_with = public.my_orchestrator()
    and lower(shared_email) = lower(auth.jwt() ->> 'email')
  );

-- The recipient reads. There is deliberately no matching policy for update or
-- delete: a book handed to you is not yours to edit or to destroy.
drop policy if exists passbook_shares_read_as_recipient on public.passbook_shares;
create policy passbook_shares_read_as_recipient on public.passbook_shares
  for select to authenticated
  using (shared_with = auth.uid());

-- updated_at is the database's, never the client's: a phone with a wrong
-- clock must not be able to claim its copy is the fresher one.
create or replace function public.passbook_shares_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists passbook_shares_touch on public.passbook_shares;
create trigger passbook_shares_touch
  before insert or update on public.passbook_shares
  for each row execute function public.passbook_shares_touch();
