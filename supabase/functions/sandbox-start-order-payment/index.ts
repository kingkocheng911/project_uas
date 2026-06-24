import {
  buildPaymentCode,
  buildSandboxQrUrl,
  buildVirtualAccountNumber,
  corsHeaders,
  createAdminClient,
  createSandboxTransactionId,
  getUserFromRequest,
  jsonResponse,
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
        'id, order_no, user_id, order_status, payment_status, grand_total, '
        + 'provider_order_id, payment_methods(code, name)',
      )
      .eq('order_no', orderNo)
      .eq('user_id', user.id)
      .maybeSingle();

    if (orderError || order == null) {
      return jsonResponse({ error: 'Pesanan tidak ditemukan.' }, 404);
    }

    if ((order['payment_status'] ?? '').toString() == 'paid') {
      return jsonResponse({ error: 'Pesanan ini sudah dibayar.' }, 400);
    }

    const paymentMethod =
      (order['payment_methods'] as Record<string, unknown> | null) ?? {};
    const paymentCode = (paymentMethod['code'] ?? '').toString();
    if (paymentCode != 'transfer_bca' && paymentCode != 'qris') {
      return jsonResponse(
        { error: 'Pesanan ini tidak menggunakan metode pembayaran sandbox yang didukung.' },
        400,
      );
    }

    const providerOrderId = (order['provider_order_id'] ?? orderNo).toString();
    const providerTransactionId = createSandboxTransactionId('TXORDER');
    const providerPaymentCode = buildPaymentCode(providerOrderId);
    const providerVaNumber = paymentCode == 'transfer_bca'
      ? buildVirtualAccountNumber(providerOrderId)
      : '';
    const providerBank = paymentCode == 'transfer_bca' ? 'bca' : '';
    const providerQrUrl = paymentCode == 'qris'
      ? buildSandboxQrUrl(providerOrderId)
      : '';
    const paymentExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000)
      .toISOString();

    const { data: updated, error: updateError } = await admin
      .from('orders')
      .update({
        provider_order_id: providerOrderId,
        provider_transaction_id: providerTransactionId,
        provider_payment_type: paymentCode == 'qris' ? 'qris' : 'bank_transfer',
        provider_payment_code: providerPaymentCode,
        provider_va_number: providerVaNumber,
        provider_bank: providerBank,
        provider_qr_url: providerQrUrl,
        provider_status: 'pending',
        provider_response: {
          mode: 'sandbox',
          provider: 'kdmp_gateway',
          generated_at: new Date().toISOString(),
        },
        payment_expires_at: paymentExpiresAt,
      })
      .eq('id', order['id'])
      .select(
        'id, order_no, order_status, payment_status, grand_total, '
        + 'provider_order_id, provider_transaction_id, provider_payment_type, provider_payment_code, '
        + 'provider_va_number, provider_bank, provider_qr_url, provider_status, payment_expires_at, payment_paid_at, '
        + 'payment_methods(code, name)',
      )
      .single();

    if (updateError || updated == null) {
      throw new Error(updateError?.message ?? 'Gagal menyimpan transaksi pembayaran.');
    }

    return jsonResponse({
      order_id: updated['id'],
      order_no: updated['order_no'],
      order_status: updated['order_status'],
      payment_status: updated['payment_status'],
      total_payment: updated['grand_total'],
      payment_method_code:
        ((updated['payment_methods'] as Record<string, unknown> | null) ?? {})['code'] ?? '',
      payment_method_name:
        ((updated['payment_methods'] as Record<string, unknown> | null) ?? {})['name'] ?? '',
      provider_order_id: updated['provider_order_id'],
      provider_transaction_id: updated['provider_transaction_id'],
      provider_payment_type: updated['provider_payment_type'],
      provider_payment_code: updated['provider_payment_code'],
      provider_va_number: updated['provider_va_number'],
      provider_bank: updated['provider_bank'],
      provider_qr_url: updated['provider_qr_url'],
      provider_status: updated['provider_status'],
      payment_expires_at: updated['payment_expires_at'],
      payment_paid_at: updated['payment_paid_at'],
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
