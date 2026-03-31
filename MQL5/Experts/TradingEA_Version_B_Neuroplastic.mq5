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

   // --- TRM Components (Tiny Recursive Model) ---
   double            m_z[4];        // Latent state vector (size 4)
   double            m_W_z[4][4];   // Recurrent weights (4x4)
   double            m_W_in[4];     // Input weights (4x1)
   double            m_W_y[4];      // Output weights (1x4)
   double            m_y;           // Current output signal

   // Helper: Tanh activation function
   double Tanh(double x)
     {
      double exp2x = MathExp(2 * x);
      return (exp2x - 1) / (exp2x + 1);
     }

public:
   CNeuroplasticBrain(int size)
     {
      m_size = size;
      ArrayResize(m_buffer, m_size);
      m_head = 0;
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
      // OPTIMIZATION: Pre-allocate buffer
      ArrayResize(m_rsiBuffer, 1);

      // --- TRM Initialization ---
      m_y = 0.0;
      ArrayInitialize(m_z, 0.0);

      // Initialize weights with pseudo-random values (Simulating pre-trained weights)
      MathSrand(GetTickCount());
      for(int i=0; i<4; i++)
        {
         m_W_in[i] = (MathRand() / 32767.0) * 2.0 - 1.0; // [-1, 1]
         m_W_y[i]  = (MathRand() / 32767.0) * 2.0 - 1.0; // [-1, 1]
         for(int j=0; j<4; j++)
            m_W_z[i][j] = (MathRand() / 32767.0) * 0.5 - 0.25; // Small recurrent weights [-0.25, 0.25]
        }
     }

   ~CNeuroplasticBrain()
     {
     }

   // TRM "Think" Process: Recursive refinement loop
   // Input: Normalized signal (e.g., RSI [0,1])
   // Returns: Refined signal [-1, 1]
   double Think(double input)
     {
      // 1. Pre-process input (center around 0)
      double x = (input - 0.5) * 2.0;

      // 2. Recursive Refinement Loop (The "Master Watchmaker" Approach)
      // Iterate K=5 times to refine the latent state based on the *current* input
      const int K = 5;

      for(int k=0; k<K; k++)
        {
         double new_z[4]; // Temporary state for this iteration (stack allocated)

         // Compute new state: z_new = Tanh(W_z * z_old + W_in * x)
         for(int i=0; i<4; i++)
           {
            double sum = 0.0;
            // Recurrent term
            for(int j=0; j<4; j++)
               sum += m_W_z[i][j] * m_z[j];

            // Input term
            sum += m_W_in[i] * x;

            new_z[i] = Tanh(sum);
           }

         // Update persistent state
         ArrayCopy(m_z, new_z);
        }

      // 3. Compute Output: y = Tanh(W_y * z)
      double sum_y = 0.0;
      for(int i=0; i<4; i++)
         sum_y += m_W_y[i] * m_z[i];

      m_y = Tanh(sum_y);
      return m_y;
     }

   // O(1) Update: No resizing, no shifting
   void Update()
     {
      // OPTIMIZATION: Use member variable instead of local allocation
      // double rsi[]; <--- Removed

      // Only copy ONE value (O(1))
      if(CopyBuffer(m_rsiHandle, 0, 0, 1, m_rsiBuffer) > 0)
        {
         double rsiNorm = m_rsiBuffer[0] / 100.0; // Normalize [0,1]
         m_buffer[m_head] = rsiNorm;
         m_head = (m_head + 1) % m_size;    // Circular increment

         // --- TRM Integration ---
         // "Think" about the new data point recursively
         double signal = Think(rsiNorm);

         // (Optional) Log the thought process occasionally
         // if(MathRand() < 100) Print("TRM Signal: ", signal);
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
