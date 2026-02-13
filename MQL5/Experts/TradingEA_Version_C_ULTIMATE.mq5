//+------------------------------------------------------------------+
//|                        TradingEA_Version_C_ULTIMATE.mq5          |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Global variables
string dashboard = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateDashboard();
  }
//+------------------------------------------------------------------+
//| Update Dashboard function                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   static ulong last_update = 0;
   ulong current_tick = GetTickCount();

   // Throttle updates to once per second (1000ms) to reduce CPU usage
   if(current_tick - last_update < 1000)
      return;

   last_update = current_tick;

   string header = "╔════════════════════════════════════════════════╗\r\n"
                   "║               TRADING DASHBOARD                ║\r\n"
                   "╠════════════════════════════════════════════════╣\r\n";
   string footer = "╚════════════════════════════════════════════════╝\r\n";

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / _Point;

   dashboard = StringFormat("%s"
                            "║ Symbol: %-38s ║\r\n"
                            "║ Bid:    %-38.*f ║\r\n"
                            "║ Ask:    %-38.*f ║\r\n"
                            "║ Spread: %-38.1f ║\r\n"
                            "%s",
                            header,
                            _Symbol,
                            _Digits, bid,
                            _Digits, ask,
                            spread,
                            footer);

   Comment(dashboard);
  }
