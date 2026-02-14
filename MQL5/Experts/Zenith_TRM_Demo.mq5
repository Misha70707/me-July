//+------------------------------------------------------------------+
//|                                              Zenith_TRM_Demo.mq5 |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Zenith\ZenithProtocol.mqh>
#include <Zenith\TinyRecursiveModel.mqh>
#include <Trade\Trade.mqh>

//--- Input Parameters
input int      InpInputSize      = 8;  // Features: dPrice, Range, Volatility, Latency, Mood, RSI, MA_Diff, Bias
input int      InpHiddenSize     = 16; // Latent Reasoning State Size (Z)
input int      InpOutputSize     = 3;  // Signal Probabilities: Buy, Sell, Hold
input int      InpRecursionCycles = 2; // TRM Outer Loop (Reasoning -> Refinement)
input int      InpReasoningSteps  = 6; // TRM Inner Loop (Deep Thought)
input double   InpSignalThreshold = 0.6; // Confidence threshold to trade

//--- Global Objects
CZenithProtocol      g_zenith;
CTinyRecursiveModel  g_brain;
CTrade               g_trade;

//--- State
datetime             g_last_bar_time = 0;
int                  g_ma_handle;
int                  g_rsi_handle;
double               g_ma_buffer[];
double               g_rsi_buffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Initialize Zenith Protocol
   g_zenith.AssessEnvironment();
   Print(g_zenith.GetStatusReport());

   // 2. Initialize Neural Brain (TRM)
   g_brain.Init(InpInputSize, InpHiddenSize, InpOutputSize);
   g_brain.RandomizeWeights(); // In production, load trained weights!

   // 3. Initialize Indicators
   g_ma_handle = iMA(_Symbol, PERIOD_CURRENT, 14, 0, MODE_SMA, PRICE_CLOSE);
   g_rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);

   if(g_ma_handle == INVALID_HANDLE || g_rsi_handle == INVALID_HANDLE)
     {
      Print("Failed to create indicator handles");
      return(INIT_FAILED);
     }

   ArraySetAsSeries(g_ma_buffer, true);
   ArraySetAsSeries(g_rsi_buffer, true);

   Print("Zenith TRM Demo EA Initialized. Ready to think deeply.");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(g_ma_handle);
   IndicatorRelease(g_rsi_handle);
   Print("Zenith TRM Demo Deinitialized.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Assess Environment (Zenith Protocol)
   g_zenith.AssessEnvironment();

   // 2. Check for New Bar (Run heavy logic only on new bar)
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(g_last_bar_time == current_time) return;
   g_last_bar_time = current_time;

   // 3. Prepare Input Vector (x)
   vector x;
   x.Resize(InpInputSize);

   // Fetch Data (Analyze Closed Bars: Index 1)
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   // Copy 2 bars starting from index 1 (Last Closed Bar)
   if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 2, rates) < 2) return;

   // Copy 1 value starting from index 1 (Last Closed Bar)
   if(CopyBuffer(g_ma_handle, 0, 1, 1, g_ma_buffer) < 1) return;
   if(CopyBuffer(g_rsi_handle, 0, 1, 1, g_rsi_buffer) < 1) return;

   // rates[0] is Bar 1 (Last Closed). rates[1] is Bar 2.
   double close0 = rates[0].close;
   double close1 = rates[1].close;
   double high0  = rates[0].high;
   double low0   = rates[0].low;

   // Normalize Inputs (Simple normalization for demo)
   // Feature 0: Price Change
   x[0] = (close0 - close1) / close1 * 100.0;
   // Feature 1: High-Low Range
   x[1] = (high0 - low0) / close0 * 100.0;
   // Feature 2: Zenith Volatility
   x[2] = g_zenith.GetVolatility();
   // Feature 3: Zenith Latency (scaled)
   x[3] = g_zenith.GetLatency() / 1000.0;
   // Feature 4: Zenith Mood
   x[4] = (double)g_zenith.GetMood();
   // Feature 5: RSI (normalized 0-1)
   x[5] = g_rsi_buffer[0] / 100.0;
   // Feature 6: Price vs MA
   x[6] = (close0 - g_ma_buffer[0]) / close0 * 100.0;
   // Feature 7: Bias
   x[7] = 1.0;

   // 4. Think! (Run TRM)
   ulong t0 = GetMicrosecondCount();
   vector y = g_brain.Think(x, InpRecursionCycles, InpReasoningSteps);
   ulong t1 = GetMicrosecondCount();

   // 5. Interpret Output (y)
   // y[0] = Buy, y[1] = Sell, y[2] = Hold
   double buy_prob  = y[0]; // Sigmoid output [0,1]
   double sell_prob = y[1];
   double hold_prob = y[2];

   // Normalize probabilities (Softmax-ish)
   double sum = buy_prob + sell_prob + hold_prob;
   if(sum > 0) {
      buy_prob /= sum;
      sell_prob /= sum;
      hold_prob /= sum;
   }

   // 6. Report Reasoning
   string decision = "HOLD";
   if(buy_prob > InpSignalThreshold && buy_prob > sell_prob) decision = "BUY";
   else if(sell_prob > InpSignalThreshold && sell_prob > buy_prob) decision = "SELL";

   string report = StringFormat(
      "TRM Thought Process:\n"
      "  Input Features: [%.2f, %.2f, ...]\n"
      "  Reasoning Time: %llu us\n"
      "  Probabilities: Buy=%.2f, Sell=%.2f, Hold=%.2f\n"
      "  Decision: %s",
      x[0], x[5], (t1-t0), buy_prob, sell_prob, hold_prob, decision
   );

   Print(report);
   Comment(report);

   // 7. Execute (Demo)
   if(decision == "BUY" && PositionsTotal() == 0)
      g_trade.Buy(0.1, _Symbol);
   else if(decision == "SELL" && PositionsTotal() == 0)
      g_trade.Sell(0.1, _Symbol);
  }
