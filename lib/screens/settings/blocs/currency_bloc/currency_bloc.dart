import 'package:flutter_bloc/flutter_bloc.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  CurrencyBloc() : super(const CurrencyInitial('VND')) {
    on<ChangeCurrency>(_onChangeCurrency);
  }

  void _onChangeCurrency(ChangeCurrency event, Emitter<CurrencyState> emit) {
    emit(CurrencyChanged(event.currency));
  }
}
