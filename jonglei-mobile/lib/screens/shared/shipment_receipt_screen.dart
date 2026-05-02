import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// ─── ShipmentReceiptScreen ────────────────────────────────────────────────────
class ShipmentReceiptScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentReceiptScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentReceiptScreen> createState() => _ShipmentReceiptScreenState();
}

class _ShipmentReceiptScreenState extends State<ShipmentReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────────
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
                  color: AppColors.onSurface, weight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
            ],
          ),

          // ── Top receipt header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHIPMENT RECEIPT',
                    style: AppTextStyles.label(
                      11,
                      color: AppColors.onSurfaceFaint,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.shipmentId,
                    style: AppTextStyles.display(
                      24,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusBadge.fromString('CLEARED'),
                      const SizedBox(width: 10),
                      Text(
                        'Issued 14 May 2026',
                        style: AppTextStyles.ui(
                          12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── QR code section ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // QR grid simulation
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 12,
                          mainAxisSpacing: 1.5,
                          crossAxisSpacing: 1.5,
                        ),
                        itemCount: 144,
                        itemBuilder: (context, index) {
                          final isLight = index % 3 != 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: isLight
                                  ? Colors.white
                                  : const Color(0xFF1B1C1A),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Shipment ID below QR
                    Text(
                      widget.shipmentId,
                      style: AppTextStyles.data(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Accordion sections ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    // 1. Sales Agreement
                    _ReceiptAccordion(
                      title: 'SALES AGREEMENT',
                      initiallyExpanded: true,
                      rows: const [
                        _AccordionRow('Seller', 'Bor Fisheries Cooperative'),
                        _AccordionRow('Buyer', 'Juba Central Market'),
                        _AccordionRow('Fish', 'Nile Perch × 120 KG'),
                        _AccordionRow('Unit Price', 'SSP 2,450/kg',
                            isData: true),
                        _AccordionRow('Total', 'SSP 294,000', isData: true),
                      ],
                    ),

                    const _SectionDivider(),

                    // 2. Transport Record
                    _ReceiptAccordion(
                      title: 'TRANSPORT RECORD',
                      initiallyExpanded: false,
                      rows: const [
                        _AccordionRow('Transporter', 'Nile Logistics Ltd'),
                        _AccordionRow('Route', 'Bor → Juba (200 km)'),
                        _AccordionRow(
                            'Departed', '13 May 2026, 06:30 CAT'),
                        _AccordionRow(
                            'Arrived', '14 May 2026, 14:15 CAT'),
                      ],
                    ),

                    const _SectionDivider(),

                    // 3. Clearance Log
                    _ReceiptAccordion(
                      title: 'CLEARANCE LOG',
                      initiallyExpanded: false,
                      rows: const [
                        _AccordionRow('Officer', 'Officer A. Deng'),
                        _AccordionRow('Checkpoint', 'Juba South Gate'),
                        _AccordionRow(
                            'Cleared At', '14 May 2026, 15:45 CAT'),
                        _AccordionRow(
                          'Blockchain Hash',
                          '0x4A3F...E291',
                          isData: true,
                          valueColor: AppColors.onSurfaceFaint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Blockchain verification strip ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VERIFIED ON LEDGER',
                            style: AppTextStyles.label(
                              10,
                              color: AppColors.success,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '0x4A3F...E291',
                            style: AppTextStyles.data(
                              12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom action buttons ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  // Download PDF
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating PDF — coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: Text(
                        'DOWNLOAD PDF',
                        style: AppTextStyles.ui(
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Share via WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'WhatsApp sharing — coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text(
                        'SHARE VIA WHATSAPP',
                        style: AppTextStyles.ui(
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
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
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
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
          style: AppTextStyles.label(
            11,
            color: AppColors.primary,
            weight: FontWeight.w700,
          ),
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
                        style: AppTextStyles.ui(
                          12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: row.isData
                            ? AppTextStyles.data(
                                12,
                                weight: FontWeight.w600,
                                color: row.valueColor ??
                                    AppColors.onSurface,
                              )
                            : AppTextStyles.ui(
                                12,
                                weight: FontWeight.w600,
                                color: row.valueColor ??
                                    AppColors.onSurface,
                              ),
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

// ─── Accordion row data ───────────────────────────────────────────────────────
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

// ─── Section divider ─────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.surfaceLow,
    );
  }
}
