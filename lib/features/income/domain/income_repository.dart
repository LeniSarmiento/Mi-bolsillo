import 'package:mi_bolsillo/features/income/domain/additional_income.dart';

/// Abstract repository contract for confirmed additional incomes.
abstract class IncomeRepository {
  Future<List<AdditionalIncome>> getAdditionalIncomes();
  Future<AdditionalIncome> addAdditionalIncome(AdditionalIncome income);
  Future<AdditionalIncome> updateAdditionalIncome(AdditionalIncome income);
  Future<void> deleteAdditionalIncome(String id);
  Future<void> clearAll();
  Future<void> resetToMockDefaults();
}
