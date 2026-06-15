insert into public.products (
  id,
  name,
  price,
  original_price,
  reward_points,
  description,
  badge,
  image_url,
  stock
)
values
  (
    'rice',
    'Beras Premium 5kg',
    65000,
    82000,
    75,
    'Beras pilihan dari mitra koperasi desa untuk kebutuhan keluarga.',
    'Cooperatively Sourced',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCYGUUcwqUMgufcQqiugoWXViQWvRED6Ju6tw8B3P6vtnWsHvR0OoH1OzL_lyhRjSmQpf7spTfKDdzYlxy-tdnV25rlnYLJ1y_Na4ZUIs7NeuphU7Y-cvmf7qzMcEfOH1jVS3L7cWYhQ46193Gi6fru9GkiO2F1S4dcBsE-K7kfgnJnvTOAc5fMhtKVPFk92C_GZUsLxn4HI2APT6vghq021oVS03pLwR0rQYmSvtCfZgM0_WTgKCmCLCONxnwzGFOiOCKueChS1Kjx',
    24
  ),
  (
    'oil',
    'Minyak Goreng 2L',
    32000,
    38000,
    28,
    'Minyak goreng jernih untuk kebutuhan dapur harian.',
    'Daily Essential',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDj7aNubhXpJ3yDOVlWGzFwo_1B8ih4-JT0z-3kbKJW2A1-t03GitLX6-4JcPTYZezlXa5QhVzAnHoM8cA5gxKaH7g6h6RJLJWeRslG9rV-O8Zt6jlG7rTuDMlkQw3hXduQYKiBMXFr_pLbw1RLqG5bd93S-dey2tE7UbmP1Yo4j6QWjzHNEQeWETOEeK8bOw6O7giju0IAx4KFh2hRQidG5lJuNnMCr5clrZTkBcSdbNNBjZdGN5F9ZffpJcQ92diS-8JH_yEwIfZc',
    36
  ),
  (
    'smartband',
    'MepuPoin Smart Band',
    199000,
    249000,
    120,
    'Smart band modern untuk anggota aktif MepuPoin.',
    'Member Favorite',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC07iseQS0S0Rfhmc607HIkovcmPRprKhd0hMLfSbq2wCS7ABJQu5EI4bQ2DZo2QsRzo8KscF86Po-DW3lScOwUxep74FuKg_6Bam56l3-m_HbdOYclkx-cD5nuGOJRrZuO637e4KOM-90w3soZ-Qf8Fo4QDSsNj-cpi_EHXUEv2lihUAQ2gkL2eMPQB6T534cuNVR7HAScJgeGE0PzvkDdS-paU2rH_phcFVtcqilA0Eie92a0nVMdGLkGofaev9em_uRIMe9zGMGg',
    12
  ),
  (
    'honey',
    'Forest Honey 250ml',
    45000,
    52000,
    32,
    'Madu hutan dari UMKM anggota koperasi dengan rasa alami.',
    'Natural Product',
    null,
    18
  )
on conflict (id) do update
set
  name = excluded.name,
  price = excluded.price,
  original_price = excluded.original_price,
  reward_points = excluded.reward_points,
  description = excluded.description,
  badge = excluded.badge,
  image_url = excluded.image_url,
  stock = excluded.stock;
