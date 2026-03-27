//+------------------------------------------------------------------+
//|                        TradingEA_Version_C_ULTIMATE.mq5          |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Global variables
string dashboard = "";

//+------------------------------------------------------------------+
//| CTinyRecursiveModel: A lightweight Recurrent Unit                |
//| Concept: Iteratively refines state 'z' and output 'y'            |
//+------------------------------------------------------------------+
class CTinyRecursiveModel
  {
private:
   double   m_state[4];    // Latent reasoning state (z)
   double   m_weights_in[4][2];  // Input weights (4 neurons, 2 inputs)
   double   m_weights_rec[4][4]; // Recurrent weights (4x4)
   double   m_weights_out[4];    // Output weights (1x4)
   int      m_depth;       // Recursion depth (thinking steps)

public:
   CTinyRecursiveModel(int depth=5) : m_depth(depth)
     {
      // Initialize with deterministic "random" weights for demo stability
      // In production, these would be loaded from a trained file
      int seed = 12345;
      for(int i=0; i<4; i++)
        {
         m_weights_out[i] = ((double)((seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF) % 2000) - 1000) / 1000.0;
         for(int j=0; j<2; j++)
            m_weights_in[i][j] = ((double)((seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF) % 2000) - 1000) / 1000.0;
         for(int j=0; j<4; j++)
            m_weights_rec[i][j] = ((double)((seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF) % 2000) - 1000) / 1000.0;
        }
     }

   // The "Thinking" Process
   // Inputs: [0] Momentum, [1] Volatility
   double Think(double input0, double input1)
     {
      // Reset state for new thought process
      ArrayInitialize(m_state, 0.0);
      double output = 0.0;

      // Recursive Refinement Loop
      for(int step=0; step<m_depth; step++)
        {
         double new_state[4];

         // Update State: z_new = Tanh(W_in * x + W_rec * z_old)
         for(int i=0; i<4; i++)
           {
            double sum = (m_weights_in[i][0] * input0) + (m_weights_in[i][1] * input1);
            for(int j=0; j<4; j++)
               sum += m_weights_rec[i][j] * m_state[j];

            new_state[i] = MathTanh(sum);
           }

         // Update Output: y = Tanh(W_out * z_new)
         double out_sum = 0.0;
         for(int i=0; i<4; i++)
           {
            m_state[i] = new_state[i]; // Commit state
            out_sum += m_weights_out[i] * m_state[i];
           }
         output = MathTanh(out_sum);
        }
      return output;
     }
  };

CTinyRecursiveModel *TRM;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   TRM = new CTinyRecursiveModel(5); // 5 steps of recursion
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(CheckPointer(TRM) == POINTER_DYNAMIC) delete TRM;
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateDashboard();
  }
//+------------------------------------------------------------------+
//| Update Dashboard function                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   static ulong last_update = 0;
   ulong current_tick = GetTickCount();

   // Throttle updates to once per second (1000ms) to reduce CPU usage
   if(current_tick - last_update < 1000)
      return;

   last_update = current_tick;

   string header = "╔════════════════════════════════════════════════╗\r\n"
                   "║               TRADING DASHBOARD                ║\r\n"
                   "╠════════════════════════════════════════════════╣\r\n";
   string footer = "╚════════════════════════════════════════════════╝\r\n";

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / _Point;

   // Simple Feature Extraction for TRM
   double close = iClose(_Symbol, PERIOD_CURRENT, 0);
   double open  = iOpen(_Symbol, PERIOD_CURRENT, 0);
   double high  = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double low   = iLow(_Symbol, PERIOD_CURRENT, 0);

   double momentum = (close - open) / _Point;
   double volatility = (high - low) / _Point;

   // TRM "Thinking"
   double signal = TRM->Think(momentum, volatility);

   // Determine sentiment string
   string sentiment = "NEUTRAL";
   if(signal > 0.3) sentiment = "BULLISH";
   if(signal < -0.3) sentiment = "BEARISH";

   dashboard = StringFormat("%s"
                            "║ Symbol:   %-36s ║\r\n"
                            "║ Bid:      %-36.*f ║\r\n"
                            "║ Ask:      %-36.*f ║\r\n"
                            "║ Spread:   %-36.1f ║\r\n"
                            "╠════════════════════════════════════════════════╣\r\n"
                            "║ TRM Sig:  %-36.4f ║\r\n"
                            "║ Mood:     %-36s ║\r\n"
                            "║ Depth:    %-36d ║\r\n"
                            "%s",
                            header,
                            _Symbol,
                            _Digits, bid,
                            _Digits, ask,
                            spread,
                            signal,
                            sentiment,
                            5, // Recursion Depth
                            footer);

   Comment(dashboard);
  }
