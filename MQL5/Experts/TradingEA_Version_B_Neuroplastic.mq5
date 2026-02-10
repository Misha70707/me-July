//+------------------------------------------------------------------+
//|                        TradingEA_Version_B_Neuroplastic.mq5      |
//|                        Copyright 2023, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Mock class to simulate the issue
class CNeuroplasticBrain
  {
private:
   int               m_rsiHandle;
   double            m_buffer[];
   int               m_head;
   int               m_size;
   // OPTIMIZATION: Persistent buffer to avoid allocation in Update()
   double            m_rsiBuffer[];

public:
   CNeuroplasticBrain(int size)
     {
      m_size = size;
      ArrayResize(m_buffer, m_size);
      m_head = 0;
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      // OPTIMIZATION: Pre-allocate buffer
      ArrayResize(m_rsiBuffer, 1);
     }

   ~CNeuroplasticBrain()
     {
     }

   // O(1) Update: No resizing, no shifting
   void Update()
     {
      // OPTIMIZATION: Use member variable instead of local allocation
      // double rsi[]; <--- Removed

      // Only copy ONE value (O(1))
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsiBuffer) > 0)
        {
         m_buffer[m_head] = m_rsiBuffer[0] / 100.0; // Normalize [0,1]
         m_head = (m_head + 1) % m_size;    // Circular increment
        }
     }
  };

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
   static CNeuroplasticBrain brain(100);
   brain.Update();
  }
//+------------------------------------------------------------------+
