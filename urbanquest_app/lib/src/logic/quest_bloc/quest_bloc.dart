
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:urbanquest_app/src/data/models/quest_model.dart';
import 'package:urbanquest_app/src/data/repositories/quest_repository.dart';

abstract class QuestEvent {}

class FetchQuests extends QuestEvent {}

abstract class QuestState {}

class QuestInitial extends QuestState {}

class QuestLoading extends QuestState {}

class QuestLoaded extends QuestState {
  final List<Quest> quests;

  QuestLoaded({required this.quests});
}

class QuestError extends QuestState {
  final String error;

  QuestError({required this.error});
}

class QuestBloc extends Bloc<QuestEvent, QuestState> {
  final QuestRepository _questRepository = QuestRepository();

  QuestBloc() : super(QuestInitial()) {
    on<FetchQuests>((event, emit) async {
      emit(QuestLoading());
      try {
        final quests = await _questRepository.getQuests();
        emit(QuestLoaded(quests: quests));
      } catch (e) {
        emit(QuestError(error: e.toString()));
      }
    });
  }
}
