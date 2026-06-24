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
    const orderNo = (payload.order_no ?? '').toString();

    if (!orderNo) {
      return jsonResponse({ error: 'Nomor pesanan wajib diisi.' }, 400);
    }

    const admin = createAdminClient();
    const { data: order, error: orderError } = await admin
      .from('orders')
      .select(
        'id, order_no, user_id, provider_order_id, payment_methods(code, name), '
        + 'provider_transaction_id, provider_payment_type, provider_payment_code, provider_va_number, provider_bank, provider_qr_url, provider_status, '
        + 'payment_expires_at, payment_paid_at, order_status, payment_status, grand_total, placed_at',
      )
      .eq('order_no', orderNo)
      .eq('user_id', user.id)
      .maybeSingle();

    if (orderError || order == null) {
      return jsonResponse({ error: 'Pesanan tidak ditemukan.' }, 404);
    }

    const providerOrderId = (order['provider_order_id'] ?? '').toString();
    if (!providerOrderId) {
      return jsonResponse({ error: 'Transaksi sandbox belum dibuat untuk pesanan ini.' }, 400);
    }

    const providerStatus = resolveSandboxProviderStatus(
      order['placed_at']?.toString() ?? null,
      order['payment_expires_at']?.toString() ?? null,
    );

    const { error: applyError } = await admin.rpc(
      'apply_order_provider_status',
      {
        p_order_id: order['id'],
        p_provider_status: providerStatus,
        p_provider_transaction_id: order['provider_transaction_id'],
        p_provider_payment_type: order['provider_payment_type'],
        p_provider_payment_code: order['provider_payment_code'],
        p_provider_va_number: order['provider_va_number'],
        p_provider_bank: order['provider_bank'],
        p_provider_qr_url: order['provider_qr_url'],
        p_provider_response: {
          mode: 'sandbox',
          provider: 'kdmp_gateway',
          checked_at: new Date().toISOString(),
          simulated_status: providerStatus,
        },
        p_paid_at: providerStatus == 'settlement' ? new Date().toISOString() : null,
        p_expires_at: order['payment_expires_at'],
      },
    );

    if (applyError) {
      throw new Error(applyError.message);
    }

    const { data: refreshed, error: refreshedError } = await admin
      .from('orders')
      .select(
        'id, order_no, order_status, payment_status, grand_total, '
        + 'provider_order_id, provider_transaction_id, provider_payment_type, provider_payment_code, '
        + 'provider_va_number, provider_bank, provider_qr_url, provider_status, payment_expires_at, payment_paid_at, '
        + 'payment_methods(code, name)',
      )
      .eq('id', order['id'])
      .single();

    if (refreshedError || refreshed == null) {
      throw new Error(refreshedError?.message ?? 'Gagal memuat status pembayaran.');
    }

    return jsonResponse({
      order_id: refreshed['id'],
      order_no: refreshed['order_no'],
      order_status: refreshed['order_status'],
      payment_status: refreshed['payment_status'],
      total_payment: refreshed['grand_total'],
      payment_method_code:
        ((refreshed['payment_methods'] as Record<string, unknown> | null) ?? {})['code'] ?? '',
      payment_method_name:
        ((refreshed['payment_methods'] as Record<string, unknown> | null) ?? {})['name'] ?? '',
      provider_order_id: refreshed['provider_order_id'],
      provider_transaction_id: refreshed['provider_transaction_id'],
      provider_payment_type: refreshed['provider_payment_type'],
      provider_payment_code: refreshed['provider_payment_code'],
      provider_va_number: refreshed['provider_va_number'],
      provider_bank: refreshed['provider_bank'],
      provider_qr_url: refreshed['provider_qr_url'],
      provider_status: refreshed['provider_status'],
      payment_expires_at: refreshed['payment_expires_at'],
      payment_paid_at: refreshed['payment_paid_at'],
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
