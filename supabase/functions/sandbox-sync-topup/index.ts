import {
  corsHeaders,
  createAdminClient,
  getUserFromRequest,
  jsonResponse,
  resolveSandboxProviderStatus,
} from '../_shared/sandbox_payments.ts';

Deno.serve(async (request) => {
  if (request.method == 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await getUserFromRequest(request);
    const payload = await request.json();
    const topupId = (payload.topup_id ?? '').toString();

    if (!topupId) {
      return jsonResponse({ error: 'ID top up wajib diisi.' }, 400);
    }

    const admin = createAdminClient();
    const { data: topup, error: topupError } = await admin
      .from('wallet_topups')
      .select('id, user_id, amount, admin_fee, total_payment, payment_method, status, sandbox_reference, payment_instruction, created_at, expires_at, paid_at, provider_order_id, provider_transaction_id, provider_payment_type, provider_payment_code, provider_va_number, provider_bank, provider_qr_url, provider_status')
      .eq('id', topupId)
      .eq('user_id', user.id)
      .maybeSingle();

    if (topupError || topup == null) {
      return jsonResponse({ error: 'Transaksi top up tidak ditemukan.' }, 404);
    }

    const providerStatus = resolveSandboxProviderStatus(
      topup['created_at']?.toString() ?? null,
      topup['expires_at']?.toString() ?? null,
    );

    const { error: applyError } = await admin.rpc(
      'apply_wallet_topup_provider_status',
      {
        p_topup_id: topupId,
        p_provider_status: providerStatus,
        p_provider_transaction_id: topup['provider_transaction_id'],
        p_provider_payment_type: topup['provider_payment_type'],
        p_provider_payment_code: topup['provider_payment_code'],
        p_provider_va_number: topup['provider_va_number'],
        p_provider_bank: topup['provider_bank'],
        p_provider_qr_url: topup['provider_qr_url'],
        p_provider_response: {
          mode: 'sandbox',
          provider: 'kdmp_gateway',
          checked_at: new Date().toISOString(),
          simulated_status: providerStatus,
        },
        p_paid_at: providerStatus == 'settlement' ? new Date().toISOString() : null,
        p_expires_at: topup['expires_at'],
      },
    );

    if (applyError) {
      throw new Error(applyError.message);
    }

    const { data: refreshed, error: refreshedError } = await admin
      .from('wallet_topups')
      .select('id, amount, admin_fee, total_payment, payment_method, status, sandbox_reference, payment_instruction, expires_at, paid_at, provider_order_id, provider_transaction_id, provider_payment_type, provider_payment_code, provider_va_number, provider_bank, provider_qr_url, provider_status')
      .eq('id', topupId)
      .single();

    if (refreshedError || refreshed == null) {
      throw new Error(refreshedError?.message ?? 'Gagal memuat status top up.');
    }

    const { data: profile } = await admin
      .from('profiles')
      .select('wallet_balance')
      .eq('id', user.id)
      .maybeSingle();

    return jsonResponse({
      topup_id: refreshed['id'],
      amount: refreshed['amount'],
      admin_fee: refreshed['admin_fee'],
      total_payment: refreshed['total_payment'],
      payment_method: refreshed['payment_method'],
      status: refreshed['status'],
      sandbox_reference: refreshed['sandbox_reference'],
      payment_instruction: refreshed['payment_instruction'],
      expires_at: refreshed['expires_at'],
      paid_at: refreshed['paid_at'],
      provider_order_id: refreshed['provider_order_id'],
      provider_transaction_id: refreshed['provider_transaction_id'],
      provider_payment_type: refreshed['provider_payment_type'],
      provider_payment_code: refreshed['provider_payment_code'],
      provider_va_number: refreshed['provider_va_number'],
      provider_bank: refreshed['provider_bank'],
      provider_qr_url: refreshed['provider_qr_url'],
      provider_status: refreshed['provider_status'],
      wallet_balance: profile?.['wallet_balance'] ?? 0,
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
