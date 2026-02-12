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

   dashboard = "╔════════════════════════════════════════════════╗\n";
   dashboard += "║               TRADING DASHBOARD                ║\n";
   dashboard += "╠════════════════════════════════════════════════╣\n";
   dashboard += "║ Symbol: " + _Symbol + "                          ║\n";
   dashboard += "║ Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "               ║\n";
   dashboard += "╚════════════════════════════════════════════════╝\n";

   Comment(dashboard);
  }
