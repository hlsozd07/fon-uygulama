import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/tefas_fund_model.dart';

class TefasService {
  /// Varlık detaylarını çeker (Hisse ve Döviz için Yahoo Finance, Fonlar için TEFAS)
  Future<TefasFundModel?> getFundDetails(String code) async {
    final upperCode = code.toUpperCase();
    
    // Önce TEFAS API'yi dene
    final tefasData = await _fetchFromTefas(upperCode);
    if (tefasData != null) return tefasData;
    
    // Bulamazsa Yahoo Finance üzerinden hisse/döviz çekmeyi dene
    return await _fetchFromYahooFinance(upperCode);
  }

  Future<TefasFundModel?> _fetchFromTefas(String code) async {
    try {
      final baseUrl = dotenv.env['TEFAS_API_URL'] ?? 'https://www.tefas.gov.tr/api/funds/fonFiyatBilgiGetir';
      final url = Uri.parse(baseUrl);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
        },
        body: json.encode({
          'fonKodu': code,
          'dil': 'TR',
          'periyod': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resultList = data['resultList'] as List?;
        if (resultList != null && resultList.isNotEmpty) {
          resultList.sort((a, b) => (a['tarih'] as String).compareTo(b['tarih'] as String));
          
          final latest = resultList.last;
          final price = (latest['fiyat'] as num).toDouble();
          final name = latest['fonUnvan'] as String;
          
          double dailyReturn = 0.0;
          if (resultList.length > 1) {
            final previous = resultList[resultList.length - 2];
            final prevPrice = (previous['fiyat'] as num).toDouble();
            if (prevPrice > 0) {
              dailyReturn = ((price - prevPrice) / prevPrice) * 100;
            }
          }

          // Satış valörünü HTML sayfasından çek
          int valor = 1; // Varsayılan olarak 1
          try {
            final detailUrl = Uri.parse('https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=$code');
            final detailResponse = await http.get(detailUrl);
            if (detailResponse.statusCode == 200) {
              final satisRegex = RegExp(r'Fon Satış Valörü</p><p class="[^"]*">(\d+)</p>');
              final satisMatch = satisRegex.firstMatch(detailResponse.body);
              if (satisMatch != null) {
                valor = int.tryParse(satisMatch.group(1) ?? '1') ?? 1;
              }
            }
          } catch (e) {
            // HTML çekimi başarısız olursa varsayılan valörde kalır
          }
          
          return TefasFundModel(
            code: code,
            name: name,
            price: price,
            valor: valor,
            dailyReturn: dailyReturn,
          );
        }
      }
    } catch (e) {
      // debugPrint veya log eklenebilir
    }
    return null;
  }

  Future<TefasFundModel?> _fetchFromYahooFinance(String code) async {
    // Kur/Hisse eşleştirme mantığı
    String querySymbol = code;
    String name = code;
    
    if (code == 'USD') { querySymbol = 'USDTRY=X'; name = 'Amerikan Doları'; }
    else if (code == 'EUR') { querySymbol = 'EURTRY=X'; name = 'Euro'; }
    else if (code == 'GLD' || code == 'ALTIN' || code == 'XAU') { querySymbol = 'GC=F'; name = 'Ons Altın'; }
    else if (!code.contains('.')) {
      // Varsayılan olarak BIST hissesi kabul et (Eğer TR'deyse)
      querySymbol = '$code.IS';
    }

    try {
      final baseUrl = dotenv.env['YAHOO_FINANCE_API_URL'] ?? 'https://query1.finance.yahoo.com/v8/finance/chart/';
      final url = Uri.parse('$baseUrl$querySymbol?interval=1d&range=1d');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'] as List?;
        if (result != null && result.isNotEmpty) {
          final meta = result.first['meta'];
          final price = (meta['regularMarketPrice'] as num).toDouble();
          final previousClose = (meta['previousClose'] as num?)?.toDouble() ?? price;
          final dailyReturn = previousClose > 0 ? ((price - previousClose) / previousClose) * 100 : 0.0;
          
          return TefasFundModel(
            code: code,
            name: name,
            price: price,
            valor: 0,
            dailyReturn: dailyReturn,
          );
        }
      }
    } catch (e) {
      // debugPrint veya log eklenebilir
    }
    
    // Eğer hiçbir şey bulunamazsa null dön
    return null;
  }
}
