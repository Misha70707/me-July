//+------------------------------------------------------------------+
//|                                              Zenith_TRM_Demo.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Zenith\ZenithProtocol.mqh>
#include <Zenith\TinyRecursiveModel.mqh>

//--- Inputs
input int      InpHiddenSize = 16;     // TRM Hidden State Size (z)
input int      InpReasoningSteps = 6;  // Inner Loop Iterations (Thinking)
input int      InpRefineSteps = 2;     // Outer Loop Iterations (Refinement)
input double   InpSignalThresh = 0.5;  // Signal Threshold

//--- Global Objects
CTrade               trade;
CZenithProtocol      zenith;
CTinyRecursiveModel  trm;
TRM_State            trm_state;

//--- Indicators
int    handle_rsi;
int    handle_ma;

//--- Time Tracking
datetime last_bar_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialize Zenith Protocol
   zenith.SetMood(MOOD_CALM);

   // Initialize Indicators
   handle_rsi = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
   handle_ma  = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);

   if(handle_rsi == INVALID_HANDLE || handle_ma == INVALID_HANDLE)
     {
      Print("Failed to create indicator handles");
      return(INIT_FAILED);
     }

   // Initialize TRM Model
   // Input Size: 5 (OHLC Normalized + RSI + MA Distance)
   // Output Size: 1 (Signal Strength -1.0 to 1.0)
   int input_size = 6;
   int output_size = 1;

   trm.Init(input_size, InpHiddenSize, output_size, InpReasoningSteps, InpRefineSteps);

   // Initialize TRM State
   trm_state.Resize(InpHiddenSize, output_size);

   Print("Zenith TRM Demo Initialized. Ready to Think.");

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handle_rsi);
   IndicatorRelease(handle_ma);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // --- New Bar Detection ---
   datetime time_curr[1];
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, 1, time_curr) <= 0) return;

   bool is_new_bar = (time_curr[0] != last_bar_time);
   last_bar_time = time_curr[0];

   // TRM is computationally heavy (recursive), run only on new bar
   if(!is_new_bar) return;

   zenith.SetMood(MOOD_FOCUSED); // Entering Thinking Mode

   // --- Prepare Input Features (x) ---
   double close[], open[], high[], low[];
   double rsi[], ma[];

   // Copy minimal data (last 1 bar)
   if(CopyClose(_Symbol, PERIOD_CURRENT, 1, 1, close) <= 0 ||
      CopyOpen(_Symbol, PERIOD_CURRENT, 1, 1, open) <= 0 ||
      CopyHigh(_Symbol, PERIOD_CURRENT, 1, 1, high) <= 0 ||
      CopyLow(_Symbol, PERIOD_CURRENT, 1, 1, low) <= 0) return;

   if(CopyBuffer(handle_rsi, 0, 1, 1, rsi) <= 0 ||
      CopyBuffer(handle_ma, 0, 1, 1, ma) <= 0) return;

   // Normalize Features (Simple Z-score like scaling for demo)
   double x[6];
   double ref_price = open[0];
   if(ref_price == 0) return;

   x[0] = (close[0] - open[0]) / ref_price * 1000.0; // Price Change
   x[1] = (high[0] - low[0]) / ref_price * 1000.0;   // Volatility Range
   x[2] = (close[0] - low[0]) / ref_price * 1000.0;  // Close position in range
   x[3] = (rsi[0] - 50.0) / 50.0;                    // RSI Normalized (-1 to 1)
   x[4] = (close[0] - ma[0]) / ref_price * 1000.0;   // Distance from MA
   x[5] = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD); // Spread Context

   // --- Run TRM (The Thinking Loop) ---
   ulong t0 = GetMicrosecondCount();

   trm.Think(x, trm_state);

   ulong t1 = GetMicrosecondCount();
   ulong latency = t1 - t0;

   // --- Interpret Result (y) ---
   double signal = trm_state.y[0];

   // Update Zenith Protocol
   zenith.UpdateMetrics(x[1], latency); // Use volatility feature as metric

   // Log Thinking Process
   string report = zenith.GetStatusReport();
   Print(report);
   PrintFormat("TRM Prediction: %.4f | Latency: %d us | Logic State (Partial): %.4f, %.4f...",
               signal, latency, trm_state.z[0], trm_state.z[1]);

   // --- Execution Logic ---
   if(signal > InpSignalThresh)
     {
      zenith.SetMood(MOOD_EXCITED);
      if(PositionsTotal() == 0)
        {
         Print("TRM Signal BUY triggered.");
         // trade.Buy(0.1, _Symbol); // Disabled for safety in demo
        }
     }
   else if(signal < -InpSignalThresh)
     {
      zenith.SetMood(MOOD_PANIC); // Or Cautious/Bearish
      if(PositionsTotal() == 0)
        {
         Print("TRM Signal SELL triggered.");
         // trade.Sell(0.1, _Symbol); // Disabled for safety in demo
        }
     }
   else
     {
      zenith.SetMood(MOOD_CALM);
     }
  }
