//+------------------------------------------------------------------+
//|                        TradingEA_Version_B_Neuroplastic.mq5      |
//|                        Copyright 2024, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Class CNeuroplasticBrain                                         |
//+------------------------------------------------------------------+
class CNeuroplasticBrain
  {
public:
                     CNeuroplasticBrain() {}
                    ~CNeuroplasticBrain() {}

   //+------------------------------------------------------------------+
   //| PrepareFeatures - Optimized to reuse buffer                      |
   //+------------------------------------------------------------------+
   bool PrepareFeatures(double &features[])
     {
      // ⚡ PERFORMANCE OPTIMIZATION:
      // Prevent unnecessary memory reallocation by checking size first.
      // Previously: ArrayResize(features, 20); called unconditionally.
      if(ArraySize(features) != 20)
        {
         if(ArrayResize(features, 20) != 20)
            return false; // Handle allocation failure
        }

      ArrayInitialize(features, 0);

      // Feature generation logic (stub)
      for(int i=0; i<20; i++)
        {
         features[i] = (double)i;
        }

      return true;
     }
  };

// Global instance
CNeuroplasticBrain ExtBrain;
// Global buffer for reuse to prevent frequent allocation in OnTick
double ExtFeaturesBuffer[];

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
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Usage: Pass the reused global buffer 'ExtFeaturesBuffer'
   if(ExtBrain.PrepareFeatures(ExtFeaturesBuffer))
     {
      // Logic to use features...
     }
  }
//+------------------------------------------------------------------+
