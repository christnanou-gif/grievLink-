-- ============================================================
-- GrievLink — LOT 2 : traitement des plaintes
-- Attribution à un agent, escalade, journal des actions, retour d'information
-- À coller dans Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1. Nouvelles colonnes sur les plaintes
alter table public.grievances add column if not exists assigned_to uuid references public.profiles(id);
alter table public.grievances add column if not exists escalated boolean not null default false;
alter table public.grievances add column if not exists escalated_at timestamptz;
alter table public.grievances add column if not exists feedback_given boolean not null default false;
alter table public.grievances add column if not exists feedback_text text;
alter table public.grievances add column if not exists feedback_date date;
alter table public.grievances add column if not exists feedback_satisfaction text
  check (feedback_satisfaction in ('Satisfait', 'Neutre', 'Insatisfait'));

-- 2. Permettre à l'agent assigné (en plus des managers/admin) de modifier le dossier
drop policy if exists grievances_update on public.grievances;
create policy grievances_update on public.grievances for update
  using (public.is_manager_or_admin() or assigned_to = auth.uid() or created_by = auth.uid());

-- 3. Journal des actions : lecture/écriture pour tout compte actif
drop policy if exists "Lecture actions" on public.actions;
drop policy if exists "Écriture actions" on public.actions;
drop policy if exists actions_select on public.actions;
drop policy if exists actions_insert on public.actions;
create policy actions_select on public.actions for select using (public.is_active_user());
create policy actions_insert on public.actions for insert with check (public.is_active_user());
