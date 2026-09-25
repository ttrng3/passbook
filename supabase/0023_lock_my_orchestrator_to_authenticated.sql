-- 0023_lock_my_orchestrator_to_authenticated.sql
--
-- 0022 said "revoke all on function public.my_orchestrator() from public;
-- grant execute to authenticated", which reads as: only a signed-in caller
-- may run it. Checked against the live API after applying it, that was not
-- what happened -- an anonymous request executed the function and got a
-- clean 200. Supabase grants EXECUTE on a new function in the public schema
-- to anon and authenticated *by name*, through default privileges, so
-- revoking from PUBLIC removes nothing: the anon grant is its own.
--
-- Nothing was exposed. The function takes no argument and reads the caller's
-- own token; an anonymous token carries no email, so it matched no row and
-- returned null, which is all it can ever return to anon. The table itself
-- was never reachable -- anon reads come back empty and an anon insert is
-- refused by RLS with 42501, both verified against the live API.
--
-- It is fixed anyway, because the gap is between what the migration claims
-- and what the database does, and on a SECURITY DEFINER function that gap is
-- the one worth closing early. A later edit that gives this function an
-- argument, or makes it read something an anonymous token can match, would
-- turn a harmless grant into a real one.
--
-- Reversible: grant execute on function public.my_orchestrator() to anon;

revoke execute on function public.my_orchestrator() from anon;

-- Say the intended state outright rather than relying on what came before.
revoke all on function public.my_orchestrator() from public;
grant execute on function public.my_orchestrator() to authenticated;
