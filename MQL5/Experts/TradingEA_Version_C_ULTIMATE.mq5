//+------------------------------------------------------------------+
//|                                TradingEA_Version_C_ULTIMATE.mq5  |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

input bool EnableBreakeven = true;
int g_handleATR;

struct Trade {
   bool breakevenSet;
   // ... other fields
};

Trade g_trades[100]; // Assuming a fixed size for simplicity

void OnTick()
{
   // ... some logic ...

   // Pre-fetch ATR for Breakeven logic
   // ZENITH OPTIMIZATION: Static allocation, handle check, no redundant API calls.
   double currentATR = 0.0;
   if(EnableBreakeven && g_handleATR != INVALID_HANDLE) {
      static double atr[1];
      if(CopyBuffer(g_handleATR, 0, 0, 1, atr) == 1) {
         currentATR = atr[0];
      }
   }

   // Loop through trades
   for(int i = 0; i < ArraySize(g_trades); i++)
   {
       // ... some trade management logic ...

        // Breakeven logic
        if(EnableBreakeven && !g_trades[i].breakevenSet) {

            // Logic using atr[0] to set breakeven...
            double beLevel = currentATR; // Example usage
            // ...
        }
   }
}
