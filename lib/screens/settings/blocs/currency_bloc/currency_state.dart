import 'package:equatable/equatable.dart';

abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object> get props => [];
}

class CurrencyInitial extends CurrencyState {
  final String currency;

  const CurrencyInitial(this.currency);

  @override
  List<Object> get props => [currency];
}

class CurrencyChanged extends CurrencyState {
  final String currency;

  const CurrencyChanged(this.currency);

  @override
  List<Object> get props => [currency];
}
