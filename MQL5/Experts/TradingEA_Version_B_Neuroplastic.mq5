//+------------------------------------------------------------------+
//|                               TradingEA_Version_B_Neuroplastic.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

class CNeuroplasticBrain
{
private:
   int m_rsiHandle;
   double m_buffer[];
   double m_rsiBuffer[]; // Optimized: Member variable to avoid reallocation
   int m_head;
   int m_size;

public:
   CNeuroplasticBrain() : m_head(0), m_size(100)
   {
      ArrayResize(m_buffer, m_size);
      ArrayResize(m_rsiBuffer, 1); // Pre-allocate size 1
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      if(m_rsiHandle == INVALID_HANDLE)
      {
         Print("Error creating RSI handle: ", GetLastError());
      }
   }

   // O(1) Update: No resizing, no shifting
   void Update()
     {
      if(m_rsiHandle == INVALID_HANDLE) return;

      // Optimized: Use member buffer
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsiBuffer) > 0)
        {
         m_buffer[m_head] = m_rsiBuffer[0] / 100.0; // Normalize [0,1]
         m_head = (m_head + 1) % m_size;    // Circular increment
        }
     }
};

CNeuroplasticBrain brain;

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   brain.Update();
}
