import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../challenges/logic/challenges_provider.dart';
import '../../data/models/challenge.dart';
import '../widgets/challenge_card.dart';

class ChallengesHomePage extends StatefulWidget {
  const ChallengesHomePage({super.key});

  @override
  State<ChallengesHomePage> createState() => _ChallengesHomePageState();
}

class _ChallengesHomePageState extends State<ChallengesHomePage> {
  ChallengeState? _filter = ChallengeState.actif;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengesProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un défi...',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        )
            : const Text('Défis'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Fermer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                if (_searching) {
                  _searchController.clear();
                }
                _searching = !_searching;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/challenges/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau défi'),
      ),
      body: Consumer<ChallengesProvider>(
        builder: (context, provider, _) {
          final searchTerm = _searchController.text.trim().toLowerCase();
          final filtered = provider.challenges.where((challenge) {
            final matchesState =
            _filter == null ? true : challenge.state == _filter;
            if (!matchesState) return false;
            if (searchTerm.isEmpty) return true;
            final title = challenge.title.toLowerCase();
            final description = challenge.description?.toLowerCase() ?? '';
            return title.contains(searchTerm) || description.contains(searchTerm);
          }).toList();
          final isLoading = provider.isLoading;
          final bodyColor = Theme.of(context).colorScheme.surface;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _StateFilterChips(
                  selected: _filter,
                  onChanged: (state) => setState(() => _filter = state),
                ),
              ),
              Expanded(
                child: Container(
                  color: bodyColor,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                      ? Center(
                    child: Text(
                      _emptyLabel(),
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: () => provider.loadAll(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 3
                            : constraints.maxWidth > 600
                            ? 2
                            : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: crossAxisCount == 1 ? 1.5 : 1.2,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final challenge = filtered[index];
                            final rate = provider.successRate(challenge.id);
                            final hasToday = provider
                                .progressFor(challenge.id)
                                .any((entry) => _isSameDay(entry.date, DateTime.now()));
                            return ChallengeCard(
                              challenge: challenge,
                              successRate: rate,
                              hasProgressToday: hasToday,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/challenges/details',
                                arguments: challenge.id,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: colorScheme.background,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _emptyLabel() {
    if (_searchController.text.trim().isNotEmpty) {
      return 'Aucun défi trouvé.';
    }
    switch (_filter) {
      case ChallengeState.actif:
        return 'Aucun défi actif.';
      case ChallengeState.en_pause:
        return 'Aucun défi en pause.';
      case ChallengeState.termine:
        return 'Aucun défi terminé.';
      case ChallengeState.echoue:
        return 'Aucun défi échoué.';
      case ChallengeState.archive:
        return 'Aucun défi archivé.';
      case null:
        return 'Aucun défi enregistré.';
    }
  }
}

class _StateFilterChips extends StatelessWidget {
  const _StateFilterChips({
    required this.selected,
    required this.onChanged,
  });

  final ChallengeState? selected;
  final ValueChanged<ChallengeState?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <ChallengeState?, String>{
      ChallengeState.actif: 'Actifs',
      ChallengeState.en_pause: 'En pause',
      ChallengeState.termine: 'Terminés',
      ChallengeState.echoue: 'Échoués',
      null: 'Tous',
    };

    return Wrap(
      spacing: 8,
      children: options.entries.map((entry) {
        final isSelected = entry.key == selected;
        return FilterChip(
          selected: isSelected,
          label: Text(entry.value),
          onSelected: (_) => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}