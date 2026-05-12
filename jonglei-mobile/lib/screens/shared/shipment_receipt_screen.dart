import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ShipmentReceiptScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentReceiptScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentReceiptScreen> createState() => _ShipmentReceiptScreenState();
}

class _ShipmentReceiptScreenState extends State<ShipmentReceiptScreen> {
  Map<String, dynamic>? _shipment;
  Map<String, dynamic>? _clearance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final shipmentFuture =
          api.get('/transport/shipments/${widget.shipmentId}/');
      final clearancesFuture = api
          .getList('/clearance/clearances/?shipment=${widget.shipmentId}');
      final shipment = await shipmentFuture;
      final clearances = await clearancesFuture;
      if (mounted) {
        setState(() {
          _shipment = shipment as Map<String, dynamic>;
          _clearance = clearances.isNotEmpty
              ? clearances.first as Map<String, dynamic>
              : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtNum(dynamic val) {
    final n = double.tryParse(val?.toString() ?? '') ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final s = _shipment;
    final c = _clearance;
    final status =
        (c?['status'] ?? s?['status'] ?? 'IN_TRANSIT').toString().toUpperCase();
    final issueDate = _fmtDate(c?['cleared_at']?.toString() ??
        c?['created_at']?.toString() ??
        s?['created_at']?.toString());
    final transporter = (s?['transporter_detail'] as Map?)
            ?['username']
            ?.toString() ??
        s?['carrier_name']?.toString() ??
        '—';

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text('Could not load receipt',
                            style: AppTextStyles.ui(15,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(_error!,
                            style: AppTextStyles.ui(12,
                                color: AppColors.onSurfaceVariant),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // ── App bar ──────────────────────────────────────────────
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.surface,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.onSurface, size: 18),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      title: Text(
                        'SHIPMENT RECEIPT',
                        style: AppTextStyles.label(13,
                            color: AppColors.onSurface,
                            weight: FontWeight.w700),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.onSurfaceVariant, size: 20),
                          onPressed: _load,
                        ),
                      ],
                    ),

                    // ── Receipt header ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.surface,
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SHIPMENT RECEIPT',
                                style: AppTextStyles.label(11,
                                    color: AppColors.onSurfaceFaint,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              widget.shipmentId,
                              style: AppTextStyles.display(18,
                                  color: AppColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                StatusBadge.fromString(status),
                                const SizedBox(width: 10),
                                Text(
                                  'Issued $issueDate',
                                  style: AppTextStyles.ui(12,
                                      color:
                                          AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── QR code ───────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              if (c != null &&
                                  c['qr_code']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true)
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(
                                        c['qr_code'] as String),
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                            AppColors.surfaceHighest),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons
                                              .qr_code_2_rounded,
                                          size: 48,
                                          color: AppColors
                                              .onSurfaceFaint),
                                      const SizedBox(height: 8),
                                      Text('QR pending clearance',
                                          style: AppTextStyles.ui(
                                              11,
                                              color: AppColors
                                                  .onSurfaceVariant),
                                          textAlign:
                                              TextAlign.center),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                widget.shipmentId,
                                style: AppTextStyles.data(13,
                                    weight: FontWeight.w700,
                                    color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Accordion sections ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                          ),
                          child: Column(
                            children: [
                              _ReceiptAccordion(
                                title: 'SALES AGREEMENT',
                                initiallyExpanded: true,
                                rows: [
                                  _AccordionRow('Seller',
                                      s?['order_seller_name']
                                              ?.toString() ??
                                          '—'),
                                  _AccordionRow('Buyer',
                                      s?['order_buyer_name']
                                              ?.toString() ??
                                          '—'),
                                  _AccordionRow(
                                    'Fish',
                                    '${s?['order_species'] ?? '—'} × ${_fmtNum(s?['order_quantity_kg'])} KG',
                                  ),
                                  _AccordionRow(
                                    'Unit Price',
                                    'SSP ${_fmtNum(s?['order_price_ssp'])}/kg',
                                    isData: true,
                                  ),
                                  _AccordionRow(
                                    'Total',
                                    'SSP ${_fmtNum(s?['order_total_price'])}',
                                    isData: true,
                                  ),
                                ],
                              ),

                              const _SectionDivider(),

                              _ReceiptAccordion(
                                title: 'TRANSPORT RECORD',
                                initiallyExpanded: false,
                                rows: [
                                  _AccordionRow(
                                      'Transporter', transporter),
                                  _AccordionRow(
                                    'Route',
                                    '${s?['origin'] ?? '—'} → ${s?['destination'] ?? '—'}',
                                  ),
                                  _AccordionRow('Departed',
                                      _fmtDate(s?['created_at']
                                          ?.toString())),
                                  _AccordionRow(
                                    'ETA / Arrived',
                                    s?['estimated_date'] != null
                                        ? _fmtDate(s!['estimated_date']
                                            .toString())
                                        : 'In transit',
                                  ),
                                ],
                              ),

                              const _SectionDivider(),

                              _ReceiptAccordion(
                                title: 'CLEARANCE LOG',
                                initiallyExpanded: false,
                                rows: c != null
                                    ? [
                                        _AccordionRow(
                                          'Officer',
                                          (c['officer_detail']
                                                      as Map?)?
                                                  ['username']
                                                  ?.toString() ??
                                              '—',
                                        ),
                                        _AccordionRow(
                                            'Checkpoint',
                                            c['checkpoint']
                                                    ?.toString() ??
                                                '—'),
                                        _AccordionRow(
                                            'Cleared At',
                                            _fmtDate(c['cleared_at']
                                                ?.toString())),
                                        _AccordionRow(
                                          'Ref ID',
                                          c['id']
                                                  ?.toString()
                                                  .substring(0, 8) ??
                                              '—',
                                          isData: true,
                                          valueColor:
                                              AppColors.onSurfaceFaint,
                                        ),
                                      ]
                                    : const [
                                        _AccordionRow('Status',
                                            'Awaiting border clearance'),
                                      ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Verification strip ────────────────────────────────────
                    if (c != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('VERIFIED ON LEDGER',
                                          style: AppTextStyles.label(10,
                                              color: AppColors.success,
                                              weight:
                                                  FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        c['id']?.toString() ?? '—',
                                        style: AppTextStyles.data(11,
                                            color: AppColors
                                                .onSurfaceVariant),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Bottom action buttons ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Generating PDF — coming soon'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                    Icons.download_outlined,
                                    size: 18),
                                label: Text(
                                  'DOWNLOAD PDF',
                                  style: AppTextStyles.ui(14,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.card),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'WhatsApp sharing — coming soon'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                    Icons.share_outlined,
                                    size: 18),
                                label: Text(
                                  'SHARE VIA WHATSAPP',
                                  style: AppTextStyles.ui(14,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.card),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Accordion section ────────────────────────────────────────────────────────
class _ReceiptAccordion extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final List<_AccordionRow> rows;

  const _ReceiptAccordion({
    required this.title,
    required this.initiallyExpanded,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(14, 0, 14, 12),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: Text(
          title,
          style: AppTextStyles.label(11,
              color: AppColors.primary, weight: FontWeight.w700),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.onSurfaceVariant,
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.label,
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: row.isData
                            ? AppTextStyles.data(12,
                                weight: FontWeight.w600,
                                color: row.valueColor ??
                                    AppColors.onSurface)
                            : AppTextStyles.ui(12,
                                weight: FontWeight.w600,
                                color: row.valueColor ??
                                    AppColors.onSurface),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AccordionRow {
  final String label;
  final String value;
  final bool isData;
  final Color? valueColor;

  const _AccordionRow(
    this.label,
    this.value, {
    this.isData = false,
    this.valueColor,
  });
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: AppColors.surfaceLow,
      );
}
