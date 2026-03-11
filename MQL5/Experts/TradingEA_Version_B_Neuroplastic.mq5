//+------------------------------------------------------------------+
//|                               TradingEA_Version_B_Neuroplastic.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Zenith/TinyRecursiveModel.mqh>

class CNeuroplasticBrain
{
private:
   int m_rsiHandle;
   double m_buffer[];
   double m_rsiBuffer[]; // Optimized: Member variable to avoid reallocation
   int m_head;
   int m_size;

   // TRM Integration
   CTinyRecursiveModel m_trm;
   double m_trmInputs[];

   // New Bar Detection
   datetime m_oldTime;

public:
   CNeuroplasticBrain() : m_head(0), m_size(100), m_oldTime(0), m_rsiHandle(INVALID_HANDLE)
   {
      ArrayResize(m_buffer, m_size);
      ArrayResize(m_rsiBuffer, 1); // Pre-allocate size 1
   }

   int Init()
   {
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      if(m_rsiHandle == INVALID_HANDLE)
      {
         Print("Error creating RSI handle: ", GetLastError());
         return INIT_FAILED;
      }

      // Initialize TRM: Input dim = 2 (RSI + Price Change), Latent dim = 8
      m_trm.Init(2, 8);
      ArrayResize(m_trmInputs, 2);

      return INIT_SUCCEEDED;
   }

   bool IsNewBar()
   {
      datetime new_time[1];
      if(CopyTime(_Symbol, _Period, 0, 1, new_time) > 0)
      {
         if(m_oldTime != new_time[0])
         {
            m_oldTime = new_time[0];
            return true;
         }
      }
      return false;
   }

   // O(1) Update: No resizing, no shifting
   void Update()
     {
      if(m_rsiHandle == INVALID_HANDLE) return;

      // Optimized: Use member buffer for RSI
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsiBuffer) > 0)
        {
         m_buffer[m_head] = m_rsiBuffer[0] / 100.0; // Normalize [0,1]
         m_head = (m_head + 1) % m_size;    // Circular increment

         // TRM Logic: Run only on New Bar to save compute
         if(IsNewBar())
         {
            // Prepare Inputs for TRM
            // 1. RSI (Normalized 0-1)
            m_trmInputs[0] = m_rsiBuffer[0] / 100.0;

            // 2. Price Change (Normalized approx)
            double close[2];
            // CopyClose(..., 0, 2, ...) copies 2 elements starting from 0 (current).
            // Default: close[0] is oldest (previous), close[1] is newest (current).
            if(CopyClose(_Symbol, _Period, 0, 2, close) == 2)
            {
               if(close[0] != 0)
               {
                   double change = (close[1] - close[0]) / close[0]; // % change (Current - Prev) / Prev
                   m_trmInputs[1] = change * 100.0; // Scale up a bit
               }
               else m_trmInputs[1] = 0.0;
            }
            else
            {
               m_trmInputs[1] = 0.0;
            }

            // "Think" using TRM
            double signal = m_trm.Think(m_trmInputs);

            // Output the reasoning result (Simulation of Trading Decision)
            Print("TRM Signal: ", signal, " | RSI: ", m_trmInputs[0], " | Change: ", m_trmInputs[1]);

            // Integration: Use signal to trigger trade (Placeholder)
            if(signal > 0.5) Print("TRM Suggests: BUY");
            if(signal < -0.5) Print("TRM Suggests: SELL");
         }
        }
     }
};

CNeuroplasticBrain brain;

int OnInit()
{
   return brain.Init();
}

void OnTick()
{
   brain.Update();
}
