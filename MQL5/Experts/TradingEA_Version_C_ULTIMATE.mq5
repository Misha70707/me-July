//+------------------------------------------------------------------+
//|                                     TradingEA_Version_C_ULTIMATE.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

string dashboard;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialization code here
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Deinitialization code here

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // --- BEGIN ISSUE CODE ---
   // File: MQL5/Experts/TradingEA_Version_C_ULTIMATE.mq5:48
   // Issue: Inefficient String Concatenation

   // Optimized using StringFormat for better performance and readability
   // This avoids multiple string allocations/concatenations and formatting intermediate strings.
   // It also ensures consistent alignment of the dashboard box (48 inner chars).
   dashboard = StringFormat(
      "╔════════════════════════════════════════════════╗\n"
      "║               TRADING DASHBOARD                ║\n"
      "╠════════════════════════════════════════════════╣\n"
      "║ Symbol: %-39s║\n"
      "║ Price: %-40.*f║\n"
      "╚════════════════════════════════════════════════╝\n",
      _Symbol,
      _Digits, SymbolInfoDouble(_Symbol, SYMBOL_BID)
   );

   Comment(dashboard);
   // --- END ISSUE CODE ---
  }
//+------------------------------------------------------------------+
