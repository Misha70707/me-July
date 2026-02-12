//+------------------------------------------------------------------+
//|                        TradingEA_Version_B_Neuroplastic.mq5      |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

// Zenith Protocol: ZERO ALLOCATION
// All memory must be pre-allocated. No dynamic ArrayResize inside OnTick.

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input double RiskPercent = 1.0;
input int    FeatureVectorSize = 10; // Number of past bars to feed
input double LearningRate = 0.01;    // Hebbian learning rate

//+------------------------------------------------------------------+
//| CFeatureManager: Zero-Allocation Circular Buffer                 |
//+------------------------------------------------------------------+
class CFeatureManager
  {
private:
   double   m_buffer[];    // Persistent buffer
   int      m_head;        // Current write index
   int      m_size;        // Buffer size
   int      m_rsiHandle;   // Indicator handle

public:
   // Constructor: O(1) initialization
   CFeatureManager(int size) : m_head(0), m_size(size)
     {
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.0);
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
     }

   ~CFeatureManager()
     {
      IndicatorRelease(m_rsiHandle);
     }

   // O(1) Update: No resizing, no shifting
   void Update()
     {
      double rsi[];
      // Only copy ONE value (O(1))
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, rsi) > 0)
        {
         m_buffer[m_head] = rsi[0] / 100.0; // Normalize [0,1]
         m_head = (m_head + 1) % m_size;    // Circular increment
        }
     }

   // Get feature at relative index (0 = newest)
   double GetFeature(int relativeIndex)
     {
      int actualIndex = (m_head - 1 - relativeIndex + m_size) % m_size;
      return m_buffer[actualIndex];
     }
  };

//+------------------------------------------------------------------+
//| CNeuroplasticBrain: Hebbian Learning Weights                     |
//+------------------------------------------------------------------+
class CNeuroplasticBrain
  {
private:
   double   m_weights[];
   int      m_inputSize;
   double   m_bias;

public:
   CNeuroplasticBrain(int inputs) : m_inputSize(inputs), m_bias(0.0)
     {
      ArrayResize(m_weights, m_inputSize);
      // Initialize with small random weights
      for(int i=0; i<m_inputSize; i++)
         m_weights[i] = (double)(MathRand() % 100) / 1000.0;
     }

   // Forward Pass: O(N) where N is small (FeatureVectorSize)
   double Predict(CFeatureManager &features)
     {
      double sum = m_bias;
      for(int i=0; i<m_inputSize; i++)
        {
         sum += features.GetFeature(i) * m_weights[i];
        }
      // Tanh activation
      return MathTanh(sum);
     }

   // Hebbian Update: Adjust weights based on outcome
   // O(N) - In-place update, zero allocation
   void Learn(CFeatureManager &features, double error)
     {
      for(int i=0; i<m_inputSize; i++)
        {
         double input = features.GetFeature(i);
         // Hebbian Rule: Weight += LearningRate * Error * Input
         m_weights[i] += LearningRate * error * input;
        }
      m_bias += LearningRate * error;
     }
  };

// Global Instances
CFeatureManager    *Features;
CNeuroplasticBrain *Brain;
CTrade              Trade;
int                 LastTradeTicket = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Allocation happens ONLY here (O(1) amortized)
   Features = new CFeatureManager(FeatureVectorSize);
   Brain    = new CNeuroplasticBrain(FeatureVectorSize);

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
   // 1. Update Features (O(1))
   Features->Update();

   // 2. Predict (O(N))
   // Dereference pointer to pass as reference
   double signal = Brain->Predict(*Features);

   // 3. Execute Trade (if strong signal)
   if(PositionsTotal() == 0)
     {
      if(signal > 0.6)
        {
         Trade.Buy(0.1, _Symbol);
         LastTradeTicket = 1; // Placeholder tracking
        }
      else if(signal < -0.6)
        {
         Trade.Sell(0.1, _Symbol);
         LastTradeTicket = -1;
        }
     }

   // 4. Learning (Simulated Feedback)
   // In real EA, check history for closed trade profit
   if(LastTradeTicket != 0)
     {
      // Simulate "Win" if signal matched random market move (mock)
      double error = (MathRand()%2 == 0 ? 1 : -1) - signal;
      Brain->Learn(*Features, error);
      LastTradeTicket = 0; // Reset
     }

   // 5. UX: Throttled Status Update (1Hz)
   static uint last_update = 0;
   if(GetTickCount() - last_update > 1000)
     {
      last_update = GetTickCount();
      string status = StringFormat(
         "🧠 NEUROPLASTIC EA v1.0\r\n"
         "═══════════════════════\r\n"
         "Signal:      %+.4f\r\n"
         "Features:    %d active\r\n"
         "Positions:   %d",
         signal,
         FeatureVectorSize,
         PositionsTotal()
      );
      Comment(status);
     }
  }
