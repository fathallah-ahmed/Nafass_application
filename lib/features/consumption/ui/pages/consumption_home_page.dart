// lib/features/consumption/ui/pages/consumption_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/consumption_entry.dart';
import '../../data/repositories/local_consumption_repository.dart';
import '../../logic/consumption_cubit.dart';
import 'add_consumption_page.dart';
import 'edit_consumption_page.dart';
import 'consumption_stats_page.dart'; // 👈 IMPORT DE LA PAGE STATS

/// 🟣 Page racine : fournit le Cubit avec le repository PERSISTANT
class ConsumptionHomePage extends StatelessWidget {
  const ConsumptionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConsumptionCubit(
        repository: LocalConsumptionRepository(),
        userId: 'demo-user', // plus tard : l'ID réel du user connecté
      ),
      child: const _ConsumptionHomeView(),
    );
  }
}

class _ConsumptionHomeView extends StatefulWidget {
  const _ConsumptionHomeView();

  @override
  State<_ConsumptionHomeView> createState() => _ConsumptionHomeViewState();
}

class _ConsumptionHomeViewState extends State<_ConsumptionHomeView> {
  DateTime? _selectedDate;
  String _selectedType = 'Tous';

  final List<String> _types = [
    'Tous',
    'Cigarette',
    'Chicha',
    'Alcool',
    'Drogue',
    'Autre',
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ConsumptionEntry entry,
  ) async {
    final cubit = context.read<ConsumptionCubit>();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la consommation'),
        content: Text(
          'Tu veux vraiment supprimer :\n'
          '${entry.substanceType} – ${entry.quantity} ${entry.unit} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cubit.deleteEntry(entry.id);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consommation supprimée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de consommation'),
        actions: [
          // 🔵 Tableau de bord : on passe le même cubit à la page stats
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Tableau de bord',
            onPressed: () {
              final cubit = context.read<ConsumptionCubit>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit, // 👈 on réutilise le même cubit
                    child: const ConsumptionStatsPage(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _pickDate(context),
            tooltip: 'Filtrer par date',
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Réinitialiser le filtre date',
            ),
        ],
      ),
      body: BlocBuilder<ConsumptionCubit, ConsumptionState>(
        builder: (context, state) {
          if (state.status == ConsumptionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ConsumptionStatus.failure) {
            return Center(
              child: Text('Erreur : ${state.errorMessage}'),
            );
          }

          var entries = state.entries;

          // Filtre date
          if (_selectedDate != null) {
            entries = entries
                .where((e) => _isSameDay(e.dateTime, _selectedDate!))
                .toList();
          }

          // Filtre type (startsWith pour "Drogue: Cannabis", etc.)
          if (_selectedType != 'Tous') {
            entries = entries
                .where((e) => e.substanceType.startsWith(_selectedType))
                .toList();
          }

          if (entries.isEmpty) {
            return Center(
              child: Text(
                (_selectedDate == null && _selectedType == 'Tous')
                    ? 'Aucune consommation enregistrée pour le moment.'
                    : 'Aucune consommation pour ces filtres.',
              ),
            );
          }

          return Column(
            children: [
              if (_selectedDate != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        'Date : '
                        '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate!.year}',
                      ),
                    ),
                  ),
                ),

              // Filtres par type
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((type) {
                      final selected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Liste des consommations
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final date = e.dateTime;

                    final dateText =
                        '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/'
                        '${date.year} '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      title: Text(
                        '${e.substanceType} – ${e.quantity} ${e.unit}',
                      ),
                      subtitle: Text(dateText),
                      onTap: () async {
                        final updated =
                            await Navigator.of(context).push<ConsumptionEntry>(
                          MaterialPageRoute(
                            builder: (_) => EditConsumptionPage(entry: e),
                          ),
                        );

                        if (updated != null) {
                          // ignore: use_build_context_synchronously
                          context
                              .read<ConsumptionCubit>()
                              .updateEntry(updated);
                        }
                      },
                      onLongPress: () => _confirmDelete(context, e),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEntry =
              await Navigator.of(context).push<ConsumptionEntry>(
            MaterialPageRoute(
              builder: (_) => const AddConsumptionPage(),
            ),
          );

          if (newEntry != null) {
            // ignore: use_build_context_synchronously
            context.read<ConsumptionCubit>().addEntry(newEntry);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
