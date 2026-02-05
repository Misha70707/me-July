//+------------------------------------------------------------------+
//|                        TradingEA_Version_B_Neuroplastic.mq5      |
//|                        Copyright 2024, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"

#include <Trade\Trade.mqh>

// ZENITH STANDARD: Eliminate Magic Numbers
#define FEATURE_VECTOR_SIZE 20

//+------------------------------------------------------------------+
//| Class CNeuroplasticBrain                                         |
//| Purpose: Encapsulates pure feature extraction logic.             |
//|          Stateless regarding memory storage.                     |
//+------------------------------------------------------------------+
class CNeuroplasticBrain
  {
public:
                     CNeuroplasticBrain() {}
                    ~CNeuroplasticBrain() {}

   //+------------------------------------------------------------------+
   //| PrepareFeatures                                                  |
   //| Optimization:                                                    |
   //| 1. Checks ArraySize to avoid reallocation (O(1) path).           |
   //| 2. REMOVED ArrayInitialize (O(N)) as data is overwritten.        |
   //+------------------------------------------------------------------+
   bool PrepareFeatures(double &features[])
     {
      // ⚡ PREVENT MEMORY CHURN
      if(ArraySize(features) != FEATURE_VECTOR_SIZE)
        {
         if(ArrayResize(features, FEATURE_VECTOR_SIZE) != FEATURE_VECTOR_SIZE)
            return false;
         // Note: Only initialize if newly resized to ensure deterministic state
         // for any untouched indices (though here we write all).
         ArrayInitialize(features, 0.0);
        }

      // ⚡ OMIT REDUNDANT ZEROING
      // Previous version called ArrayInitialize(0) here every tick.
      // Since we overwrite 0..FEATURE_VECTOR_SIZE-1, that was wasted CPU.

      // Feature generation loop (Tight loop)
      for(int i=0; i<FEATURE_VECTOR_SIZE; i++)
        {
         features[i] = (double)i * 1.0001;
        }

      return true;
     }
  };

//+------------------------------------------------------------------+
//| Class CFeatureManager                                            |
//| Purpose: Manages persistent memory for features (RAII pattern).  |
//|          Prevents global namespace pollution.                    |
//+------------------------------------------------------------------+
class CFeatureManager
  {
private:
   double            m_buffer[]; // Persistent memory, allocated once (mostly)

public:
                     CFeatureManager() {}
                    ~CFeatureManager() {}

   //+------------------------------------------------------------------+
   //| UpdateAndProcess                                                 |
   //| Orchestrates the brain's logic using internal managed memory.    |
   //+------------------------------------------------------------------+
   void UpdateAndProcess(CNeuroplasticBrain &brain)
     {
      // Pass internal buffer to brain.
      // Memory is reused across ticks.
      if(brain.PrepareFeatures(m_buffer))
        {
         // Execute Inference / Trading Logic
         // ...
        }
     }
  };

// Global Modules (Stateless or Managers)
CNeuroplasticBrain ExtBrain;
CFeatureManager    ExtFeatureManager;

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
   // ZENITH EXECUTION:
   // Modular call. No global arrays exposed in OnTick.
   // Memory efficiency is handled inside CFeatureManager.
   ExtFeatureManager.UpdateAndProcess(ExtBrain);
  }
