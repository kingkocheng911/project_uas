import {
  corsHeaders,
  createAdminClient,
  createSandboxReference,
  createSandboxTransactionId,
  getUserFromRequest,
  jsonResponse,
  buildPaymentCode,
  buildSandboxQrUrl,
  buildVirtualAccountNumber,
} from '../_shared/sandbox_payments.ts';

const adminFee = 1000;

Deno.serve(async (request) => {
  if (request.method == 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await getUserFromRequest(request);
    const payload = await request.json();
    const amount = Number(payload.amount ?? 0);
    const method = (payload.method ?? '').toString();
    const bank = (payload.bank ?? 'bca').toString().toLowerCase();

    if (!Number.isInteger(amount) || amount < 10000) {
      return jsonResponse({ error: 'Minimal top up Rp 10.000.' }, 400);
    }

    if (method != 'qris' && method != 'virtual_account') {
      return jsonResponse({ error: 'Metode pembayaran tidak didukung.' }, 400);
    }

    const admin = createAdminClient();
    const totalPayment = amount + adminFee;
    const orderId = createSandboxReference('TOPUP');
    const transactionId = createSandboxTransactionId('TXTOPUP');
    const paymentCode = buildPaymentCode(orderId);
    const vaNumber = method == 'virtual_account'
      ? buildVirtualAccountNumber(orderId)
      : '';
    const qrUrl = method == 'qris' ? buildSandboxQrUrl(orderId) : '';
    const instruction = method == 'qris'
      ? 'Scan QRIS sandbox lalu tekan cek status setelah simulasi pembayaran selesai.'
      : 'Gunakan nomor Virtual Account sandbox lalu tekan cek status setelah simulasi pembayaran selesai.';

    const { data: created, error: createError } = await admin
      .from('wallet_topups')
      .insert({
        user_id: user.id,
        amount,
        admin_fee: adminFee,
        total_payment: totalPayment,
        payment_method: method,
        status: 'pending',
        sandbox_provider: 'kdmp_gateway',
        sandbox_reference: orderId,
        provider_order_id: orderId,
        provider_transaction_id: transactionId,
        provider_payment_type: method == 'qris' ? 'qris' : 'bank_transfer',
        provider_payment_code: paymentCode,
        provider_va_number: vaNumber,
        provider_bank: method == 'virtual_account' ? bank : '',
        provider_qr_url: qrUrl,
        provider_status: 'pending',
        payment_instruction: instruction,
        provider_response: {
          mode: 'sandbox',
          provider: 'kdmp_gateway',
          generated_at: new Date().toISOString(),
        },
        metadata: {
          mode: 'sandbox',
          provider: 'kdmp_gateway',
          requested_bank: bank,
        },
      })
      .select('id, amount, admin_fee, total_payment, payment_method, status, sandbox_reference, payment_instruction, expires_at, paid_at, provider_order_id, provider_transaction_id, provider_payment_type, provider_payment_code, provider_va_number, provider_bank, provider_qr_url, provider_status')
      .single();

    if (createError || !created) {
      throw new Error(createError?.message ?? 'Gagal membuat transaksi top up.');
    }

    return jsonResponse({
      topup_id: created['id'],
      amount: created['amount'],
      admin_fee: created['admin_fee'],
      total_payment: created['total_payment'],
      payment_method: created['payment_method'],
      status: created['status'],
      sandbox_reference: created['sandbox_reference'],
      payment_instruction: created['payment_instruction'],
      expires_at: created['expires_at'],
      paid_at: created['paid_at'],
      provider_order_id: created['provider_order_id'],
      provider_transaction_id: created['provider_transaction_id'],
      provider_payment_type: created['provider_payment_type'],
      provider_payment_code: created['provider_payment_code'],
      provider_va_number: created['provider_va_number'],
      provider_bank: created['provider_bank'],
      provider_qr_url: created['provider_qr_url'],
      provider_status: created['provider_status'],
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
