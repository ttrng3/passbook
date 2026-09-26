-- 0024_my_orchestrator_refuses_anon.sql
--
-- 0023 said it locked my_orchestrator() to signed-in callers. It did not.
-- Read directly from the live database on 2026-09-26:
--
--   proacl = {postgres=X/postgres,anon=X/postgres,
--             authenticated=X/postgres,service_role=X/postgres}
--
-- anon had EXECUTE the whole time, which is why an anonymous POST to
-- /rest/v1/rpc/my_orchestrator kept answering 200. It was never a PostgREST
-- plan cache, which is what two rounds of guessing assumed; the grant simply
-- was not gone.
--
-- THE CAUSE, and it will bite again: Supabase ships
--   alter default privileges in schema public grant execute on functions
--     to anon, authenticated, service_role
-- so every new function in `public` is granted to anon BY NAME. `revoke all
-- ... from public` -- which is what 0022 wrote -- removes the PUBLIC grant
-- and leaves the anon grant untouched. **In this project, revoking from
-- PUBLIC is not revoking from anon.** Say anon explicitly or it keeps its
-- privilege.
--
-- Checked while fixing, so the next person does not have to: CREATE OR
-- REPLACE does NOT re-apply the default privileges. Revoke before or after a
-- replace, either is fine; the ACL survives.
--
-- Nothing was exposed at any point. The function takes no argument and reads
-- the caller's own token, so an anonymous token matched no row and returned
-- null, which is the only thing it could ever return to anon. The table it
-- guards was never reachable: anon reads come back [] and an anon insert is
-- refused 42501, both re-verified after this migration.
--
-- Two locks now, because one of them turned out to be a claim rather than a
-- fact for a day and a half:
--
--   1. The grant. anon named explicitly.
--   2. The body. `auth.uid() is not null` cannot match for an anonymous
--      token, so even with EXECUTE the function has nothing to say. A
--      privilege can be quietly restored by a later default; a WHERE clause
--      cannot.
--
-- Verified after applying, against the live project:
--   anon    -> HTTP 401, 42501 "permission denied for function my_orchestrator"
--   invited -> returns that person's inviter, matching family_invites.invited_by
--
-- Reversible: drop the auth.uid() line and `grant execute ... to anon`.

create or replace function public.my_orchestrator()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select invited_by
    from public.family_invites
   where auth.uid() is not null
     and lower(email) = lower(auth.jwt() ->> 'email')
   limit 1
$$;

revoke all     on function public.my_orchestrator() from public;
revoke execute on function public.my_orchestrator() from anon;   -- the line 0023 needed
grant  execute on function public.my_orchestrator() to authenticated;

notify pgrst, 'reload schema';
