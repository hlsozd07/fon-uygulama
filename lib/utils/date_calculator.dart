class DateCalculator {
  /// Hesaplanacak hedef tarih ve valör gün sayısına göre
  /// en son ne zaman satış emri girilmesi gerektiğini bulur.
  static DateTime calculateSellDate(DateTime targetDate, int valorDays) {
    DateTime moneyArrivalDate = targetDate;
    
    // Eğer hedef tarih haftasonuna denk geliyorsa, paranın en geç
    // cuma günü elde olması gerekir.
    if (moneyArrivalDate.weekday == DateTime.saturday) {
      moneyArrivalDate = moneyArrivalDate.subtract(const Duration(days: 1));
    } else if (moneyArrivalDate.weekday == DateTime.sunday) {
      moneyArrivalDate = moneyArrivalDate.subtract(const Duration(days: 2));
    }

    DateTime sellDate = moneyArrivalDate;
    int daysToSubtract = valorDays;

    // Geriye doğru iş günlerini sayarak satış tarihini bul.
    while (daysToSubtract > 0) {
      sellDate = sellDate.subtract(const Duration(days: 1));
      if (sellDate.weekday != DateTime.saturday && sellDate.weekday != DateTime.sunday) {
        daysToSubtract--;
      }
    }

    // Saat bilgisini 13:30 olarak ayarlayalım (Türkiye'deki fonlar için standart kesim saati)
    return DateTime(sellDate.year, sellDate.month, sellDate.day, 13, 30);
  }
}
