import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/challenge.dart';
import '../../data/models/challenge_progress.dart';
import '../../logic/challenges_provider.dart';
import '../widgets/challenge_stats.dart';

class ChallengeDetailsPage extends StatefulWidget {
  const ChallengeDetailsPage({super.key});

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  String? _challengeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _challengeId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du défi'),
        actions: [
          if (_challengeId != null)
            Consumer<ChallengesProvider>(
              builder: (context, provider, _) {
                final challenge = _findChallenge(provider);
                if (challenge == null) {
                  return const SizedBox.shrink();
                }
                return PopupMenuButton<_ChallengeMenuAction>(
                  onSelected: (action) => _handleAction(action, provider, challenge),
                  itemBuilder: (context) {
                    final isArchived = challenge.state == ChallengeState.archive;
                    return [
                      const PopupMenuItem(
                        value: _ChallengeMenuAction.edit,
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: _ChallengeMenuAction.complete,
                        enabled: !isArchived,
                        child: const Text('Marquer comme terminé'),
                      ),
                      PopupMenuItem(
                        value: _ChallengeMenuAction.fail,
                        enabled: !isArchived,
                        child: const Text('Marquer comme échoué'),
                      ),
                      PopupMenuItem(
                        value: _ChallengeMenuAction.archive,
                        enabled: challenge.state != ChallengeState.archive,
                        child: const Text('Archiver'),
                      ),
                      const PopupMenuItem(
                        value: _ChallengeMenuAction.delete,
                        child: Text('Supprimer définitivement'),
                      ),
                    ];
                  },
                );
              },
            ),
        ],
      ),
      floatingActionButton: _challengeId == null
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _showAddProgressSheet(context),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Ajouter un suivi'),
      ),
      body: _challengeId == null
          ? const Center(child: Text('Défi introuvable'))
          : Consumer<ChallengesProvider>(
        builder: (context, provider, _) {
          final challenge = _findChallenge(provider);
          if (challenge == null) {
            return const Center(child: Text('Défi introuvable'));
          }
          final history = provider.progressFor(challenge.id);
          final weekRate = provider.successRate(challenge.id, days: 7);
          final monthRate = provider.successRate(challenge.id);
          final dateFormat = DateFormat('dd MMM yyyy', 'fr');
          final reminder = challenge.reminderTime != null
              ? _formatReminder(context, challenge)
              : 'Aucun';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(challenge: challenge),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Type',
                          value: _capitalize(challenge.typeAddiction),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Fréquence',
                          value: challenge.frequency == ChallengeFrequency.quotidien
                              ? 'Quotidienne'
                              : 'Hebdomadaire',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.calendar_month_rounded,
                          label: 'Période',
                          value:
                          '${dateFormat.format(challenge.startDate)} → ${challenge.isIndefinite ? 'indéfini' : challenge.endDate != null ? dateFormat.format(challenge.endDate!) : 'indéfini'}',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.notifications_active_rounded,
                          label: 'Rappel',
                          value: reminder,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ChallengeStats(
                  weekRate: weekRate,
                  monthRate: monthRate,
                  history: history,
                ),
                const SizedBox(height: 24),
                Text(
                  'Historique',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Aucune entrée pour le moment. Ajoutez votre premier suivi !',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = history[history.length - index - 1];
                      return _ProgressTile(
                        progress: entry,
                        onDelete: () => provider.deleteProgress(entry.id),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Challenge? _findChallenge(ChallengesProvider provider) {
    if (_challengeId == null) return null;
    try {
      return provider.challenges.firstWhere((challenge) => challenge.id == _challengeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleAction(
      _ChallengeMenuAction action,
      ChallengesProvider provider,
      Challenge challenge,
      ) async {
    switch (action) {
      case _ChallengeMenuAction.edit:
        Navigator.pushNamed(context, '/challenges/new', arguments: challenge.id);
        break;
      case _ChallengeMenuAction.archive:
        await provider.archiveChallenge(challenge.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Défi archivé.')),
          );
        }
        break;
      case _ChallengeMenuAction.complete:
        await _updateState(provider, challenge, ChallengeState.termine);
        break;
      case _ChallengeMenuAction.fail:
        await _updateState(provider, challenge, ChallengeState.echoue);
        break;
      case _ChallengeMenuAction.delete:
        await provider.deleteChallengeHard(challenge.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Défi supprimé.')),
          );
        }
        break;
    }
  }

  Future<void> _updateState(
      ChallengesProvider provider,
      Challenge challenge,
      ChallengeState target,
      ) async {
    if (challenge.state == target) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(target == ChallengeState.termine
                ? 'Le défi est déjà terminé.'
                : 'Le défi est déjà marqué comme échoué.'),
          ),
        );
      }
      return;
    }
    final now = DateTime.now();
    final metadata = <String, dynamic>{
      ...?challenge.metadata,
      if (target == ChallengeState.termine) 'completedAt': now.toIso8601String(),
      if (target == ChallengeState.echoue) 'failedAt': now.toIso8601String(),
      'updatedManually': true,
    };
    final updated = challenge.copyWith(state: target, metadata: metadata);
    await provider.updateChallenge(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(target == ChallengeState.termine
              ? 'Défi marqué comme terminé.'
              : 'Défi marqué comme échoué.'),
        ),
      );
    }
  }

  void _showAddProgressSheet(BuildContext context) {
    final provider = context.read<ChallengesProvider>();
    final challenge = _findChallenge(provider);
    if (challenge == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ProgressForm(
          challengeId: challenge.id,
        );
      },
    );
  }

  String _formatReminder(BuildContext context, Challenge challenge) {
    final parts = challenge.reminderTime?.split(':') ?? <String>[];
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final timeLabel = timeOfDay.format(context);
    if (challenge.frequency == ChallengeFrequency.quotidien) {
      return 'Chaque jour à $timeLabel';
    }
    final weekday = DateFormat('EEEE', 'fr').format(challenge.startDate);
    return 'Chaque $weekday à $timeLabel';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stateLabel = _stateLabel(challenge.state);
    final chipColor = _stateColor(challenge.state, colorScheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          challenge.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(stateLabel),
          backgroundColor: chipColor,
        ),
      ],
    );
  }

  static String _stateLabel(ChallengeState state) {
    switch (state) {
      case ChallengeState.actif:
        return 'Actif';
      case ChallengeState.en_pause:
        return 'En pause';
      case ChallengeState.termine:
        return 'Terminé';
      case ChallengeState.echoue:
        return 'Échoué';
      case ChallengeState.archive:
        return 'Archivé';
    }
  }

  static Color _stateColor(ChallengeState state, ColorScheme scheme) {
    switch (state) {
      case ChallengeState.actif:
        return scheme.secondaryContainer;
      case ChallengeState.en_pause:
        return scheme.tertiaryContainer;
      case ChallengeState.termine:
        return scheme.primaryContainer;
      case ChallengeState.echoue:
        return scheme.errorContainer;
      case ChallengeState.archive:
        return scheme.surfaceVariant;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.progress,
    required this.onDelete,
  });

  final ChallengeProgress progress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE dd MMM', 'fr');
    final success = progress.success;
    final hasValue = progress.measuredValue != null;
    final colorScheme = Theme.of(context).colorScheme;
    final icon = success == true
        ? Icons.check_circle_rounded
        : success == false
        ? Icons.cancel_rounded
        : Icons.analytics_rounded;
    final iconColor = success == true
        ? colorScheme.primary
        : success == false
        ? colorScheme.error
        : colorScheme.secondary;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(dateFormat.format(progress.date)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasValue)
              Text('Valeur relevée : ${progress.measuredValue?.toStringAsFixed(2)}'),
            if (success != null)
              Text(success ? 'Succès' : 'Échec'),
            if (progress.note != null && progress.note!.isNotEmpty)
              Text(progress.note!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _ProgressForm extends StatefulWidget {
  const _ProgressForm({required this.challengeId});

  final String challengeId;

  @override
  State<_ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends State<_ProgressForm> {
  DateTime _date = DateTime.now();
  bool? _success = true;
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle entrée',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(DateFormat('dd MMM yyyy', 'fr').format(_date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(_date.year - 1),
                    lastDate: DateTime(_date.year + 1),
                    locale: const Locale('fr'),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _success,
                tristate: true,
                title: const Text('Succès'),
                subtitle: const Text('Indiquez si l\'objectif a été atteint'),
                onChanged: (value) {
                  setState(() => _success = value);
                },
              ),
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valeur mesurée (optionnel)',
                ),
              ),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<ChallengesProvider>();
    final value = double.tryParse(_valueController.text.trim());
    if (_success == null && value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseignez un succès ou une valeur mesurée.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await provider.addDailyProgress(
        challengeId: widget.challengeId,
        date: DateFormat('yyyy-MM-dd').format(_date),
        success: _success,
        measuredValue: value,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ajouter le suivi : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

enum _ChallengeMenuAction { edit, archive, complete, fail, delete }