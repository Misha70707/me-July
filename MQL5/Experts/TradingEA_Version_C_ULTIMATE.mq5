//+------------------------------------------------------------------+
//|                                     TradingEA_Version_C_ULTIMATE.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.01"

#include <Trade/Trade.mqh>
#include <Zenith/TinyRecursiveModel.mqh>

// Global Objects
CTrade trade;
CTinyRecursiveModel trm;
string dashboard;

// Indicator Handles
int hRSI, hMAFast, hMASlow, hATR;

// State Variables
double lastClosePrice = 0.0;
double lastPrediction = 0.0;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialize Indicators
   hRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
   hMAFast = iMA(_Symbol, PERIOD_CURRENT, 10, 0, MODE_SMA, PRICE_CLOSE);
   hMASlow = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, 14);

   if(hRSI == INVALID_HANDLE || hMAFast == INVALID_HANDLE ||
      hMASlow == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("Error creating indicator handles");
      return(INIT_FAILED);
   }

   trm.ResetState();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(hRSI);
   IndicatorRelease(hMAFast);
   IndicatorRelease(hMASlow);
   IndicatorRelease(hATR);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check for New Bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == lastBarTime) return; // Only run logic on new bar

   // --- Fetch Data ---
   double rsi[], maFast[], maSlow[], atr[], close[];
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(close, true);

   if(CopyBuffer(hRSI, 0, 1, 1, rsi) <= 0 ||
      CopyBuffer(hMAFast, 0, 1, 1, maFast) <= 0 ||
      CopyBuffer(hMASlow, 0, 1, 1, maSlow) <= 0 ||
      CopyBuffer(hATR, 0, 1, 1, atr) <= 0 ||
      CopyClose(_Symbol, PERIOD_CURRENT, 1, 1, close) <= 0)
   {
      return; // Data not ready
   }

   // --- Online Learning Step (Retroactive) ---
   // If we made a prediction last bar, check if it was right
   if(lastClosePrice > 0.0)
   {
      double priceChange = close[0] - lastClosePrice;
      double actualOutcome = (priceChange > 0) ? 1.0 : -1.0; // Simple direction
      // Teach the model based on last bar's error
      trm.Learn(actualOutcome);
   }
   lastClosePrice = close[0];

   // --- Inference Step (Tiny Recursive Model) ---
   // Calculate momentum proxy
   double momentum = (close[0] - iClose(_Symbol, PERIOD_CURRENT, 2));

   // Think-Loop: Forward pass with recursion
   double prediction = trm.Think(rsi[0], maFast[0], maSlow[0], atr[0], momentum);
   lastPrediction = prediction;

   // --- Execution Logic ---
   if(prediction > 0.6) // Buy Threshold
   {
      if(PositionsTotal() == 0) trade.Buy(0.1, _Symbol);
   }
   else if(prediction < -0.6) // Sell Threshold
   {
      if(PositionsTotal() == 0) trade.Sell(0.1, _Symbol);
   }

   // --- Dashboard Update ---
   // Optimized using StringFormat for better performance and readability
   dashboard = StringFormat(
      "╔════════════════════════════════════════════════╗\n"
      "║               TRADING DASHBOARD                ║\n"
      "╠════════════════════════════════════════════════╣\n"
      "║ Symbol: %-39s║\n"
      "║ Price: %-40.*f║\n"
      "║ TRM Signal: %-35.4f║\n"
      "║ TRM State: %-36s║\n"
      "╚════════════════════════════════════════════════╝\n",
      _Symbol,
      _Digits, SymbolInfoDouble(_Symbol, SYMBOL_BID),
      prediction,
      (prediction > 0.6 ? "BULLISH" : (prediction < -0.6 ? "BEARISH" : "NEUTRAL"))
   );

   Comment(dashboard);

   lastBarTime = currentBarTime;
  }
//+------------------------------------------------------------------+
