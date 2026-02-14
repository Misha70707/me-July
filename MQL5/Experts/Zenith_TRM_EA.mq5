//+------------------------------------------------------------------+
//|                                           Zenith_TRM_EA.mq5      |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Zenith/ZenithProtocol.mqh>
#include <Zenith/TinyRecursiveModel.mqh>

// Zenith Protocol: ZERO ALLOCATION
// The TRM runs only on new bars (O(Bar)) instead of ticks (O(Tick))

// Input Parameters
input int    InputVectorSize = 10; // Number of inputs (e.g., Close, Vol, RSI...)
input int    HiddenStateSize = 10; // Size of latent reasoning (z)
input int    RecursionDepth  = 6;  // How many times to "think" per bar

// Global Objects
CZenithProtocol     *Zenith;
CTinyRecursiveModel *Brain;
CTrade              Trade;

// State Variables
datetime m_last_bar_time;
double   m_input_vector[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Zenith Protocol: Allocation happens ONLY here.
   Zenith = new CZenithProtocol();
   Brain  = new CTinyRecursiveModel(HiddenStateSize, RecursionDepth);

   ArrayResize(m_input_vector, InputVectorSize);

   // Self-Diagnostic Check
   if(!Zenith->SelfDiagnose())
     {
      Print("Zenith Critical Failure: Initialization Aborted.");
      return(INIT_FAILED);
     }

   Print("Zenith TRM Initialized. Recursion Depth: ", RecursionDepth);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete Zenith;
   delete Brain;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Check for New Bar (Best Practice: Run heavy TRM only once per bar)
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_time == m_last_bar_time) return;

   m_last_bar_time = current_time;

   // 2. Assess Environment (Volatility, Latency)
   Zenith->AssessEnvironment();
   ENUM_ZENITH_MOOD mood = Zenith->GetMood();

   // 3. Skip "Thinking" if system is overloaded or mood is bad
   if(mood == MOOD_LAGGY || mood == MOOD_ANXIOUS)
     {
      Print("Zenith Mood: ", EnumToString(mood), ". Skipping TRM cycle.");
      return;
     }

   // 4. Collect Input Data (x)
   CollectFeatures(m_input_vector);

   // 5. Run Tiny Recursive Model (The "Think-Loop")
   ulong t_start = GetMicrosecondCount();
   double signal = Brain->Think(m_input_vector);
   ulong t_end = GetMicrosecondCount();

   PrintFormat("TRM Thought Cycle Complete. Signal: %.4f | Time: %llu us", signal, t_end - t_start);

   // 6. Execute Trade based on "y" (Prediction)
   if(PositionsTotal() == 0)
     {
      if(signal > 0.5)       Trade.Buy(0.1, _Symbol);
      else if(signal < -0.5) Trade.Sell(0.1, _Symbol);
     }

   // 7. Update Dashboard
   string report = Zenith->GetStatusReport();
   report += "\n╔════════════ TRM ENGINE ════════════╗\n";
   report += StringFormat("║ Signal: %-26.4f ║\n", signal);
   report += StringFormat("║ Depth:  %-26d ║\n", RecursionDepth);
   report += "╚════════════════════════════════════╝";
   Comment(report);
  }

//+------------------------------------------------------------------+
//| Feature Collection Helper                                        |
//+------------------------------------------------------------------+
void CollectFeatures(double &inputs[])
  {
   // Simple example: Normalize Close prices and RSI
   // In production: Fill with comprehensive market data
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, InputVectorSize, rates) > 0)
     {
      // Normalize (simple z-score mock)
      double sum = 0, sq_sum = 0;
      for(int i=0; i<InputVectorSize; i++)
        {
         sum += rates[i].close;
         sq_sum += rates[i].close * rates[i].close;
        }
      double mean = sum / InputVectorSize;
      double std = MathSqrt(sq_sum/InputVectorSize - mean*mean);

      for(int i=0; i<InputVectorSize; i++)
        {
         if(std > 0) inputs[i] = (rates[i].close - mean) / std;
         else        inputs[i] = 0;
        }
     }
  }
