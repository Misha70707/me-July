//+------------------------------------------------------------------+
//|                                     TradingEA_Version_D_TRM.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <TinyRecursiveModel.mqh>

//--- Input Parameters
input int      InpReasoningSteps = 6;    // Number of Reasoning Steps (N)
input int      InpRefinementCycles = 2;  // Number of Refinement Cycles (T)
input int      InpHiddenDim = 16;        // Hidden State Dimension (Size of z)
input double   InpLotSize = 0.1;         // Trading Lot Size
input int      InpStopLoss = 50;         // Stop Loss (Points)
input int      InpTakeProfit = 100;      // Take Profit (Points)
input int      InpRSIPeriod = 14;        // RSI Period
input int      InpMAPeriod = 20;         // MA Period

//--- Global Objects
CTrade               trade;
CTinyRecursiveModel  trm;

//--- Indicator Handles
int    h_rsi;
int    h_ma;

//--- State Variables
datetime last_bar_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Initialize Indicators
   h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   h_ma  = iMA(_Symbol, _Period, InpMAPeriod, 0, MODE_SMA, PRICE_CLOSE);

   if(h_rsi == INVALID_HANDLE || h_ma == INVALID_HANDLE)
     {
      Print("Error: Failed to create indicator handles.");
      return INIT_FAILED;
     }

   // 2. Initialize Tiny Recursive Model
   // Input Dimension:
   // 0: Close Price (Normalized)
   // 1: MA Deviation (Normalized)
   // 2: RSI (Normalized 0-1)
   // Total Input Dim = 3
   int input_dim = 3;

   trm.Init(input_dim, InpHiddenDim, InpReasoningSteps, InpRefinementCycles);

   Print("TRM Initialized. Hidden Dim: ", InpHiddenDim,
         ", Reasoning Steps: ", InpReasoningSteps,
         ", Refinement Cycles: ", InpRefinementCycles);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(h_rsi);
   IndicatorRelease(h_ma);
   Comment("");
  }
//+------------------------------------------------------------------+
//| New Bar Detection Helper                                         |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime current_time = iTime(_Symbol, _Period, 0);
   if(current_time != last_bar_time)
     {
      last_bar_time = current_time;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Data Collection & Normalization                                  |
//+------------------------------------------------------------------+
bool GetModelInputs(vector &inputs)
  {
   inputs.Resize(3);

   // Fetch Data
   double close[], rsi[], ma[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(ma, true);

   if(CopyClose(_Symbol, _Period, 0, 1, close) < 1 ||
      CopyBuffer(h_rsi, 0, 0, 1, rsi) < 1 ||
      CopyBuffer(h_ma, 0, 0, 1, ma) < 1)
     {
      return false;
     }

   // Normalize Inputs (Simple Z-score proxy or MinMax)
   // 1. Price vs MA Deviation: (Close - MA) / Point
   double deviation = (close[0] - ma[0]) / _Point;
   // Clamp to reasonable range (e.g., -100 to 100 points -> -1 to 1)
   double norm_deviation = MathMax(-1.0, MathMin(1.0, deviation / 100.0));

   // 2. RSI: 0-100 -> 0-1 -> -0.5 to 0.5 (centered)
   double norm_rsi = (rsi[0] / 100.0) - 0.5;

   // 3. Price Change (Log Return): ln(Close / PrevClose)
   // Need previous close.
   double close_prev[1];
   if(CopyClose(_Symbol, _Period, 1, 1, close_prev) < 1) return false;
   double log_return = MathLog(close[0] / close_prev[0]);
   // Scale return (e.g., *1000)
   double norm_return = MathMax(-1.0, MathMin(1.0, log_return * 1000.0));

   // Populate Vector
   inputs[0] = norm_deviation;
   inputs[1] = norm_rsi;
   inputs[2] = norm_return;

   return true;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check for New Bar to run costly inference
   if(!IsNewBar()) return;

   // 1. Prepare Input Vector
   vector x;
   if(!GetModelInputs(x)) return;

   // 2. Run TRM Prediction
   // Note: Since this is an untrained model with random weights,
   // the output is for demonstration of architecture flow only.
   double signal = trm.Predict(x);

   // 3. Trading Logic (Threshold > 0.5 or < -0.5)
   // "Dopamine" threshold logic could be applied here

   string comment = StringFormat(
      "TRM Status:\n"
      "Cycles: %d | Steps: %d\n"
      "Signal: %.4f\n",
      InpRefinementCycles, InpReasoningSteps, signal
   );

   if(signal > 0.5)
     {
      if(PositionsTotal() == 0)
        {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl = ask - InpStopLoss * _Point;
         double tp = ask + InpTakeProfit * _Point;
         trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "TRM Buy");
         comment += "Action: BUY";
        }
     }
   else if(signal < -0.5)
     {
      if(PositionsTotal() == 0)
        {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl = bid + InpStopLoss * _Point;
         double tp = bid - InpTakeProfit * _Point;
         trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "TRM Sell");
         comment += "Action: SELL";
        }
     }
   else
     {
      comment += "Action: HOLD";
     }

   Comment(comment);
  }
//+------------------------------------------------------------------+
