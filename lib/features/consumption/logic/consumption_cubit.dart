// lib/features/consumption/logic/consumption_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/consumption_entry.dart';
import '../data/repositories/consumption_repository.dart';

/// Statut global de la partie Suivi
enum ConsumptionStatus {
  initial,
  loading,
  success,
  failure,
}

/// État du cubit
class ConsumptionState {
  final ConsumptionStatus status;
  final List<ConsumptionEntry> entries;
  final String? errorMessage;

  const ConsumptionState({
    this.status = ConsumptionStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  ConsumptionState copyWith({
    ConsumptionStatus? status,
    List<ConsumptionEntry>? entries,
    String? errorMessage,
  }) {
    return ConsumptionState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Cubit qui gère le suivi de consommation
class ConsumptionCubit extends Cubit<ConsumptionState> {
  final ConsumptionRepository _repository;
  final String _userId;

  StreamSubscription<List<ConsumptionEntry>>? _subscription;

  ConsumptionCubit({
    required ConsumptionRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const ConsumptionState()) {
    _subscribeToEntries();
  }

  /// Abonnement au flux de données du repository
  void _subscribeToEntries() {
    emit(state.copyWith(status: ConsumptionStatus.loading));

    _subscription = _repository.watchEntries(_userId).listen(
      (entries) {
        emit(
          state.copyWith(
            status: ConsumptionStatus.success,
            entries: entries,
            errorMessage: null,
          ),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: ConsumptionStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  /// Récupération manuelle (si tu veux forcer un refresh)
  Future<void> fetchEntries() async {
    try {
      emit(state.copyWith(status: ConsumptionStatus.loading));
      final entries = await _repository.getEntries(_userId);
      emit(
        state.copyWith(
          status: ConsumptionStatus.success,
          entries: entries,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ConsumptionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Ajouter une consommation
  Future<void> addEntry(ConsumptionEntry entry) async {
    try {
      await _repository.addEntry(entry);
    } catch (e) {
      emit(
        state.copyWith(
          status: ConsumptionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Modifier une consommation
  Future<void> updateEntry(ConsumptionEntry entry) async {
    try {
      await _repository.updateEntry(entry);
    } catch (e) {
      emit(
        state.copyWith(
          status: ConsumptionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Supprimer une consommation
  Future<void> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
    } catch (e) {
      emit(
        state.copyWith(
          status: ConsumptionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
