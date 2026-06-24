update public.wallet_topups
set
  sandbox_provider = 'kdmp_gateway',
  metadata = case
    when jsonb_typeof(metadata) = 'object' and metadata ? 'provider'
      then jsonb_set(metadata, '{provider}', '"kdmp_gateway"', true)
    else metadata
  end,
  provider_response = case
    when jsonb_typeof(provider_response) = 'object' and provider_response ? 'provider'
      then jsonb_set(provider_response, '{provider}', '"kdmp_gateway"', true)
    else provider_response
  end
where sandbox_provider = 'midtrans'
   or (jsonb_typeof(metadata) = 'object' and metadata ->> 'provider' = 'midtrans')
   or (jsonb_typeof(provider_response) = 'object' and provider_response ->> 'provider' = 'midtrans');
