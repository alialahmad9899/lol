import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/payment_request_repository.dart';

class AdminPaymentRequestsPage extends StatefulWidget {
  const AdminPaymentRequestsPage({super.key, required this.reviewerUid});

  final String reviewerUid;

  @override
  State<AdminPaymentRequestsPage> createState() =>
      _AdminPaymentRequestsPageState();
}

class _AdminPaymentRequestsPageState extends State<AdminPaymentRequestsPage> {
  late final PaymentRequestRepository _repository =
      PaymentRequestRepository();
  final Set<String> _reviewingIds = <String>{};

  Future<void> _review(
    PaymentRequest request, {
    required bool approve,
  }) async {
    final TextEditingController noteController = TextEditingController();
    String? note;
    try {
      note = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
          title: Text(approve ? 'اعتماد طلب الدفع' : 'رفض طلب الدفع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                approve
                    ? 'تأكدت من وصول التحويل فعلياً ومطابقة المبلغ والمرجع؟ '
                        'سيتم فتح الكورس للمستخدم بعد الاعتماد.'
                    : 'اكتب سبب الرفض ليظهر للمستخدم، حتى يعرف ما الذي يحتاج إلى تصحيحه.',
                style: const TextStyle(height: 1.6),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: approve ? 1 : 2,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: approve ? 'ملاحظة (اختيارية)' : 'سبب الرفض',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final String value = noteController.text.trim();
                if (!approve && value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(approve ? 'تأكيد الاعتماد' : 'تأكيد الرفض'),
            ),
          ],
        );
        },
      );
    } finally {
      noteController.dispose();
    }
    if (note == null || _reviewingIds.contains(request.id)) return;

    setState(() => _reviewingIds.add(request.id));
    try {
      await _repository.reviewRequest(
        requestId: request.id,
        reviewerUid: widget.reviewerUid,
        approve: approve,
        reviewNote: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'تم اعتماد الطلب وفتح الكورس للمستخدم.'
                : 'تم رفض الطلب وإرسال سبب الرفض إلى المستخدم.',
          ),
          backgroundColor: RoohTheme.primary,
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: const Color(0xFF9B382B),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذرت مراجعة الطلب. تحقق من صلاحيات الإدارة واتصال قاعدة البيانات.',
          ),
          backgroundColor: Color(0xFF9B382B),
        ),
      );
    } finally {
      if (mounted) setState(() => _reviewingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الدفع اليدوي')),
      body: StreamBuilder<List<PaymentRequest>>(
        stream: _repository.watchPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _PaymentReviewMessage(
              title: 'تعذر تحميل طلبات الدفع',
              message:
                  'تحقق من صلاحيات المدير وقواعد Firestore ثم أعد المحاولة.',
              icon: Icons.cloud_off_outlined,
            );
          }

          final List<PaymentRequest> requests =
              snapshot.data ?? const <PaymentRequest>[];
          if (requests.isEmpty) {
            return const _PaymentReviewMessage(
              title: 'لا توجد طلبات معلّقة',
              message: 'ستظهر هنا طلبات التحويل التي يرسلها المستخدمون.',
              icon: Icons.inbox_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final PaymentRequest request = requests[index];
              return _PaymentRequestCard(
                request: request,
                onApprove: () => _review(request, approve: true),
                onReject: () => _review(request, approve: false),
                isBusy: _reviewingIds.contains(request.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentRequestCard extends StatelessWidget {
  const _PaymentRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.isBusy,
  });

  final PaymentRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: RoohTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoohTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.receipt_long_outlined, color: RoohTheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  request.courseTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Text(
                'قيد المراجعة',
                style: TextStyle(
                  color: RoohTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PaymentDetailRow(
            label: 'المبلغ',
            value: '${request.amount} ${request.currency}',
          ),
          const SizedBox(height: 8),
          _PaymentDetailRow(
            label: 'مرجع التحويل',
            value: request.transferReference,
            selectable: true,
          ),
          const SizedBox(height: 8),
          _PaymentDetailRow(
            label: 'معرّف المستخدم',
            value: request.userId,
            selectable: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'تحقق من التحويل في وسيلة الدفع خارج التطبيق قبل الموافقة. '
            'إدخال المرجع وحده لا يثبت وصول المبلغ.',
            style: TextStyle(
              color: RoohTheme.mutedInk,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onApprove,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(isBusy ? 'جارٍ الحفظ...' : 'اعتماد'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  const _PaymentDetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              color: RoohTheme.mutedInk,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: selectable
              ? SelectableText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )
              : Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

class _PaymentReviewMessage extends StatelessWidget {
  const _PaymentReviewMessage({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: RoohTheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RoohTheme.mutedInk,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
