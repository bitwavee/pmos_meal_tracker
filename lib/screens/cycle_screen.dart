import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/period_log.dart';
import '../providers/app_providers.dart';
import '../services/database_service.dart';

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleOverviewProvider);
    final periodsAsync = ref.watch(periodsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cycle Tracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              cycleAsync.when(
                data: (cycle) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E24AA), Color(0xFFC084FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Predicted next period',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat('MMM d, yyyy').format(cycle.nextPeriodDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Average cycle length: ${cycle.averageCycleLength} days',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (error, stack) => const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Unable to load cycle data'))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showPeriodDialog(context, ref),
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: const Text('Log period start'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Previous periods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: periodsAsync.when(
                  data: (periods) {
                    if (periods.isEmpty) {
                      return const Center(
                        child: Text('No period history yet. Start by logging your first cycle.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: periods.length,
                      itemBuilder: (context, index) {
                        final period = periods[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('MMM d, yyyy').format(period.startDate),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'End: ${period.endDate == null ? 'Not recorded' : DateFormat('MMM d, yyyy').format(period.endDate!)}',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(period.status.label),
                                backgroundColor: _statusColor(period.status),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Unable to load cycle history: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(PeriodStatus status) {
    switch (status) {
      case PeriodStatus.early:
        return const Color(0xFFE8F5E9);
      case PeriodStatus.onTime:
        return const Color(0xFFFFF8E1);
      case PeriodStatus.late:
        return const Color(0xFFFFEBEE);
    }
  }

  Future<void> _showPeriodDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    PeriodStatus status = PeriodStatus.onTime;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log period start'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final chosen = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (chosen != null) {
                      startDate = chosen;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Period start date',
                    ),
                    child: Text(DateFormat('MMM d, yyyy').format(startDate)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final chosen = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (chosen != null) {
                      endDate = chosen;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Period end date (optional)',
                    ),
                    child: Text(endDate == null ? 'Not set' : DateFormat('MMM d, yyyy').format(endDate!)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PeriodStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Status',
                  ),
                  items: PeriodStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      status = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final db = DatabaseService.instance;
                  await db.savePeriod(
                    PeriodLog(
                      startDate: startDate,
                      endDate: endDate,
                      status: status,
                    ),
                  );
                  ref.invalidate(cycleOverviewProvider);
                  ref.invalidate(periodsProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
