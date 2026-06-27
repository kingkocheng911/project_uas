update public.products
set
  category_labels = array_remove(category_labels, 'Alat-alat'),
  updated_at = now()
where 'Alat-alat' = any(category_labels);
update public.promotions
set
  category_id = null,
  updated_at = now()
where category_id in (
  select id
  from public.categories
  where label = 'Alat-alat'
);
delete from public.categories
where label = 'Alat-alat';
