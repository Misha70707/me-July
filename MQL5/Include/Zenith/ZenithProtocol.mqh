//+------------------------------------------------------------------+
//|                                               ZenithProtocol.mqh |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

class CZenithProtocol
  {
private:
   MqlRates          m_rates[]; // Persistent buffer for volatility calculation

public:
                     CZenithProtocol();
                    ~CZenithProtocol();
   double            CalculateVolatility();
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CZenithProtocol::CZenithProtocol()
  {
   // Pre-allocate buffer to avoid reallocation on every tick
   ArrayResize(m_rates, 1);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CZenithProtocol::~CZenithProtocol()
  {
  }
//+------------------------------------------------------------------+
//| Calculate immediate volatility (High - Low of current bar)       |
//+------------------------------------------------------------------+
double CZenithProtocol::CalculateVolatility()
  {
   // Use member variable m_rates to avoid allocation overhead
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 1, m_rates) > 0)
     {
      return m_rates[0].high - m_rates[0].low;
     }
   return 0.0;
  }
//+------------------------------------------------------------------+
