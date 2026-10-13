create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 120),
  description text not null default '' check (char_length(description) <= 500),
  due_date date,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'todo' check (status in ('todo', 'inprogress', 'done')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.tasks enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;

drop policy if exists "Signed-in users can view shared tasks" on public.tasks;
create policy "Signed-in users can view shared tasks"
  on public.tasks for select
  to authenticated
  using (true);

drop policy if exists "Signed-in users can add shared tasks" on public.tasks;
create policy "Signed-in users can add shared tasks"
  on public.tasks for insert
  to authenticated
  with check (true);

drop policy if exists "Signed-in users can update shared tasks" on public.tasks;
create policy "Signed-in users can update shared tasks"
  on public.tasks for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Signed-in users can delete shared tasks" on public.tasks;
create policy "Signed-in users can delete shared tasks"
  on public.tasks for delete
  to authenticated
  using (true);

create or replace function public.set_task_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at
  before update on public.tasks
  for each row execute function public.set_task_updated_at();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'tasks'
  ) then
    alter publication supabase_realtime add table public.tasks;
  end if;
end;
$$;
