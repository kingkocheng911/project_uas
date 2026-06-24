import { createClient } from 'npm:@supabase/supabase-js@2';

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

export function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

export function getRequiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
}

export function createAdminClient() {
  return createClient(
    getRequiredEnv('SUPABASE_URL'),
    getRequiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
    {
      auth: {
        persistSession: false,
      },
    },
  );
}

export async function getUserFromRequest(request: Request) {
  const authHeader = request.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();

  if (!token) {
    throw new Error('Missing bearer token');
  }

  const client = createAdminClient();
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) {
    throw new Error('Unauthorized');
  }

  return data.user;
}

export function createSandboxReference(prefix: string) {
  return `${prefix}-${Date.now()}-${crypto.randomUUID().replaceAll('-', '').slice(0, 8).toUpperCase()}`;
}

export function createSandboxTransactionId(prefix: string) {
  return `${prefix}-${crypto.randomUUID().replaceAll('-', '').slice(0, 12).toUpperCase()}`;
}

export function buildVirtualAccountNumber(seed: string) {
  const digits = seed.replaceAll(/\D/g, '');
  const suffix = digits.slice(-10).padStart(10, '0');
  return `8808${suffix}`;
}

export function buildPaymentCode(seed: string) {
  const cleaned = seed.replaceAll(/[^A-Z0-9]/g, '');
  return cleaned.slice(-10).padStart(10, '0');
}

export function buildSandboxQrUrl(reference: string) {
  const text = encodeURIComponent(`KDMP SANDBOX ${reference}`);
  return `https://quickchart.io/qr?text=${text}&size=320`;
}

export function resolveSandboxProviderStatus(
  createdAt: string | null,
  expiresAt: string | null,
) {
  const now = Date.now();
  const created = createdAt ? Date.parse(createdAt) : now;
  const expires = expiresAt ? Date.parse(expiresAt) : now + 30 * 60 * 1000;

  if (!Number.isNaN(expires) && now > expires) {
    return 'expire';
  }

  if (!Number.isNaN(created) && now - created >= 5000) {
    return 'settlement';
  }

  return 'pending';
}
