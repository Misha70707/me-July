//+------------------------------------------------------------------+
//|                        TradingEA_Version_B_Neuroplastic.mq5      |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.00"

#include <Trade/Trade.mqh>
#include <TinyRecursiveModel.mqh> // TRM Core

// Zenith Protocol: ZERO ALLOCATION
// All memory must be pre-allocated. No dynamic ArrayResize inside OnTick.

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input double RiskPercent = 1.0;
input int    TRM_ThinkLoops = 6;    // "Deep Thought" cycles (T)
input int    TRM_InnerLoops = 2;    // Latent reasoning steps (n)
input int    TRM_HiddenSize = 12;   // Size of reasoning vector (z)

//+------------------------------------------------------------------+
//| CFeatureManager: Feature Engineering for TRM                     |
//+------------------------------------------------------------------+
class CFeatureManager
  {
private:
   double   m_features[];  // Current feature vector
   int      m_rsiHandle;
   int      m_maHandle;
   int      m_bbHandle;

   // Zero-Allocation Buffers
   double   m_rsi_buf[];
   double   m_ma_buf[];
   double   m_close_buf[];
   double   m_bb_upper_buf[];
   double   m_bb_lower_buf[];

public:
   CFeatureManager()
     {
      ArrayResize(m_features, 3); // [RSI, MA_Dev, BB_Pos]
      ArrayInitialize(m_features, 0.0);

      // Pre-allocate temp buffers (Size 1)
      ArrayResize(m_rsi_buf, 1);
      ArrayResize(m_ma_buf, 1);
      ArrayResize(m_close_buf, 1);
      ArrayResize(m_bb_upper_buf, 1);
      ArrayResize(m_bb_lower_buf, 1);

      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      m_maHandle  = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
      m_bbHandle  = iBands(_Symbol, PERIOD_CURRENT, 20, 2.0, 0, PRICE_CLOSE);
     }

   ~CFeatureManager()
     {
      IndicatorRelease(m_rsiHandle);
      IndicatorRelease(m_maHandle);
      IndicatorRelease(m_bbHandle);
     }

   // Update features (O(1) CopyBuffer calls)
   void Update()
     {
      // 1. Get Price Data first (Common dependency)
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, m_close_buf) <= 0) return;
      double close = m_close_buf[0];

      // 2. RSI
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsi_buf) > 0)
         m_features[0] = m_rsi_buf[0] / 100.0;

      // 3. MA Deviation
      if(CopyBuffer(m_maHandle, 0, 0, 1, m_ma_buf) > 0)
        {
         if(close > 0)
            m_features[1] = (close - m_ma_buf[0]) / close * 100.0;
        }

      // 4. Bollinger Bands %B
      if(CopyBuffer(m_bbHandle, 1, 0, 1, m_bb_upper_buf) > 0 &&
         CopyBuffer(m_bbHandle, 2, 0, 1, m_bb_lower_buf) > 0)
        {
         double width = m_bb_upper_buf[0] - m_bb_lower_buf[0];
         if(width > 0)
            m_features[2] = (close - m_bb_lower_buf[0]) / width;
         else
            m_features[2] = 0.5;
        }
     }

   // Return reference to feature vector
   void GetFeatures(double &out_features[])
     {
      ArrayCopy(out_features, m_features);
     }
  };

// Global Instances
CFeatureManager     *Features;
CTinyRecursiveModel *Brain;
CTrade               Trade;
double               LastSignal = 0.0;
double               InputVector[]; // Persistent input buffer

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Allocation happens ONLY here
   Features = new CFeatureManager();
   // Inputs: 3 (RSI, MA, BB), Hidden: User Input, Output: 1 (Signal)
   Brain    = new CTinyRecursiveModel(3, TRM_HiddenSize, 1, TRM_ThinkLoops, TRM_InnerLoops);

   ArrayResize(InputVector, 3);
   ArrayInitialize(InputVector, 0.0);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete Features;
   delete Brain;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. New Bar Detection (Critical for Performance)
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar = false;

   if(CopyTime(_Symbol, _Period, 0, 1, New_Time) > 0)
     {
      if(Old_Time != New_Time[0])
        {
         IsNewBar = true;
         Old_Time = New_Time[0];
        }
     }

   // 2. TRM Logic (Only on New Bar)
   if(IsNewBar)
     {
      // Update Features
      Features->Update();

      // Zero-Allocation Get: Copy into pre-allocated buffer
      Features->GetFeatures(InputVector);

      // Deep Thought (Recursive Inference)
      LastSignal = Brain->Think(InputVector);

      // Execute Trade
      if(PositionsTotal() == 0)
        {
         if(LastSignal > 0.6)
            Trade.Buy(0.1, _Symbol);
         else if(LastSignal < -0.6)
            Trade.Sell(0.1, _Symbol);
        }

      // Simulate "Learning" (Placeholder for feedback loop)
      // In production, this would use closed trade history
      Brain->Adapt(0.0);
     }

   // 3. UX: Throttled Status Update (1Hz)
   static uint last_update = 0;
   if(GetTickCount() - last_update > 1000)
     {
      last_update = GetTickCount();
      string status = StringFormat(
         "🧠 TINY RECURSIVE MODEL (TRM)\r\n"
         "═════════════════════════════\r\n"
         "Signal:      %+.4f\r\n"
         "Think Loops: %d (x%d)\r\n"
         "Positions:   %d",
         LastSignal,
         TRM_ThinkLoops,
         TRM_InnerLoops,
         PositionsTotal()
      );
      Comment(status);
     }
  }
