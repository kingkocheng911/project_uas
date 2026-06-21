do $$
declare
  v_branch_id uuid;
begin
  select id into v_branch_id
  from public.branches
  where code = 'KDMP-SLO-01'
  limit 1;

  if v_branch_id is not null then
    perform *
    from public._system_upsert_branch_admin_account(
      v_branch_id,
      'admin.banjarsari@kdmp.id',
      'Banjarsari#2026',
      'Admin KDMP Solo Banjarsari',
      '+62 271 555 0101',
      'branch_admin',
      true
    );
  end if;

  select id into v_branch_id
  from public.branches
  where code = 'KDMP-SLO-02'
  limit 1;

  if v_branch_id is not null then
    perform *
    from public._system_upsert_branch_admin_account(
      v_branch_id,
      'admin.jebres@kdmp.id',
      'Jebres#2026',
      'Admin KDMP Solo Jebres',
      '+62 271 555 0102',
      'branch_admin',
      true
    );
  end if;

  select id into v_branch_id
  from public.branches
  where id = '81da52f0-febc-4cb3-af12-013c610d4293'::uuid
  limit 1;

  if v_branch_id is not null then
    perform *
    from public._system_upsert_branch_admin_account(
      v_branch_id,
      'admin.menco@kdmp.id',
      'Menco#2026',
      'Admin Cabang Menco',
      '98362766773',
      'branch_admin',
      true
    );
  end if;
end
$$;
