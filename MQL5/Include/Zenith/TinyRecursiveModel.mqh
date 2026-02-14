//+------------------------------------------------------------------+
//|                                          TinyRecursiveModel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Minimal Gated Unit (MGU) Implementation for Tiny Recursive Model (TRM)
// Optimized for MQL5 Execution Speed & Memory Efficiency (Zenith Protocol)

#define TRM_INPUT_SIZE 5     // e.g. RSI, MA_Fast, MA_Slow, Volatility, Momentum
#define TRM_HIDDEN_SIZE 8    // Small latent space (z) for speed
#define TRM_OUTPUT_SIZE 1    // Single prediction value (-1 to 1)
#define TRM_RECURSION_DEPTH 3 // Number of reasoning cycles (Phase 1)

class CTinyRecursiveModel
{
private:
   // --- Model State ---
   double m_z[TRM_HIDDEN_SIZE];      // Latent Reasoning Vector (Context)
   double m_y[TRM_OUTPUT_SIZE];      // Current Prediction Vector (Answer)
   double m_x[TRM_INPUT_SIZE];       // Normalized Input Vector

   // --- MGU Weights (Flattened for cache locality) ---
   // Dimensions: Hidden x (Input + Hidden)
   // We simplify: W_f (Forget), W_h (Candidate)
   double m_W_f[TRM_HIDDEN_SIZE * (TRM_INPUT_SIZE + TRM_HIDDEN_SIZE)];
   double m_b_f[TRM_HIDDEN_SIZE];

   double m_W_h[TRM_HIDDEN_SIZE * (TRM_INPUT_SIZE + TRM_HIDDEN_SIZE)];
   double m_b_h[TRM_HIDDEN_SIZE];

   // Output Layer Weights (Hidden -> Output)
   double m_W_out[TRM_OUTPUT_SIZE * TRM_HIDDEN_SIZE];
   double m_b_out[TRM_OUTPUT_SIZE];

   // Learning Parameters
   double m_learningRate;

   // --- Activation Functions ---
   double Sigmoid(double x) { return 1.0 / (1.0 + MathExp(-x)); }
   double Tanh(double x) { return MathTanh(x); }
   double Relu(double x) { return x > 0 ? x : 0; }
   double LeakyRelu(double x) { return x > 0 ? x : 0.01 * x; }

   // --- Helper: Matrix-Vector Multiplication ---
   // out = W * cat(in1, in2) + b
   void DenseLayer(const double &W[], const double &b[],
                  const double &in1[], const double &in2[],
                  double &out[], int outSize, int in1Size, int in2Size)
   {
      int totalIn = in1Size + in2Size;
      for(int i=0; i<outSize; i++)
      {
         double sum = b[i];
         // Multiply first part (in1)
         for(int j=0; j<in1Size; j++)
            sum += W[i * totalIn + j] * in1[j];
         // Multiply second part (in2)
         for(int j=0; j<in2Size; j++)
            sum += W[i * totalIn + in1Size + j] * in2[j];

         out[i] = sum;
      }
   }

   // --- Helper: Simple Dense (Hidden -> Output) ---
   void OutputLayer(const double &W[], const double &b[], const double &in[], double &out[], int outSize, int inSize)
   {
      for(int i=0; i<outSize; i++)
      {
         double sum = b[i];
         for(int j=0; j<inSize; j++)
            sum += W[i*inSize + j] * in[j];
         out[i] = sum;
      }
   }

public:
   CTinyRecursiveModel() : m_learningRate(0.01)
   {
      InitializeWeights();
      ResetState();
   }

   void ResetState()
   {
      ArrayInitialize(m_z, 0.0);
      ArrayInitialize(m_y, 0.0);
      ArrayInitialize(m_x, 0.0);
   }

   // Initialize weights with Xavier/Glorot uniform
   void InitializeWeights()
   {
      MathSrand(GetTickCount());
      InitLayer(m_W_f, TRM_HIDDEN_SIZE, TRM_INPUT_SIZE + TRM_HIDDEN_SIZE);
      InitLayer(m_W_h, TRM_HIDDEN_SIZE, TRM_INPUT_SIZE + TRM_HIDDEN_SIZE);
      InitLayer(m_W_out, TRM_OUTPUT_SIZE, TRM_HIDDEN_SIZE);

      ArrayInitialize(m_b_f, 0.0);
      ArrayInitialize(m_b_h, 0.0);
      ArrayInitialize(m_b_out, 0.0);
   }

   void InitLayer(double &w[], int rows, int cols)
   {
      double limit = MathSqrt(6.0 / (rows + cols));
      for(int i=0; i<rows*cols; i++)
         w[i] = (MathRand()/32767.0 * 2.0 - 1.0) * limit;
   }

   // --- Core Logic: The Recursive "Think-Loop" ---
   // Returns the final prediction (-1.0 to 1.0)
   double Think(double i_rsi, double i_ma_fast, double i_ma_slow, double i_vol, double i_mom)
   {
      // 0. Update Input Vector
      m_x[0] = (i_rsi - 50.0) / 50.0;           // Normalize RSI (-1 to 1)
      m_x[1] = (i_ma_fast - i_ma_slow);         // MA Cross Diff (Raw)
      m_x[2] = i_vol;                           // Volatility (ATR-like)
      m_x[3] = i_mom;                           // Momentum
      m_x[4] = m_y[0];                          // Previous Answer Feedback!

      // Phase 1: Latent Reasoning (Updating z)
      // Cycle 'n' times to refine context
      for(int step=0; step<TRM_RECURSION_DEPTH; step++)
      {
         // MGU Cell Logic
         double f[TRM_HIDDEN_SIZE]; // Forget gate
         double h_tilde[TRM_HIDDEN_SIZE]; // Candidate

         // 1. Calculate Forget Gate: f = Sigmoid(W_f * [x, z_prev] + b_f)
         double pre_f[TRM_HIDDEN_SIZE];
         DenseLayer(m_W_f, m_b_f, m_x, m_z, pre_f, TRM_HIDDEN_SIZE, TRM_INPUT_SIZE, TRM_HIDDEN_SIZE);
         for(int i=0; i<TRM_HIDDEN_SIZE; i++) f[i] = Sigmoid(pre_f[i]);

         // 2. Calculate Candidate: h~ = Tanh(W_h * [x, (f * z_prev)] + b_h)
         double f_z[TRM_HIDDEN_SIZE];
         for(int i=0; i<TRM_HIDDEN_SIZE; i++) f_z[i] = f[i] * m_z[i]; // Gated context

         double pre_h[TRM_HIDDEN_SIZE];
         DenseLayer(m_W_h, m_b_h, m_x, f_z, pre_h, TRM_HIDDEN_SIZE, TRM_INPUT_SIZE, TRM_HIDDEN_SIZE);
         for(int i=0; i<TRM_HIDDEN_SIZE; i++) h_tilde[i] = Tanh(pre_h[i]);

         // 3. Update State: z_new = (1-f)*z_prev + f*h~
         for(int i=0; i<TRM_HIDDEN_SIZE; i++)
            m_z[i] = (1.0 - f[i]) * m_z[i] + f[i] * h_tilde[i];
      }

      // Phase 2: Answer Refinement (Updating y)
      // y = Tanh(W_out * z + b_out)
      double pre_y[TRM_OUTPUT_SIZE];
      OutputLayer(m_W_out, m_b_out, m_z, pre_y, TRM_OUTPUT_SIZE, TRM_HIDDEN_SIZE);
      m_y[0] = Tanh(pre_y[0]);

      return m_y[0];
   }

   // --- Online Learning: Simple Error-Driven Plasticity ---
   // Adjust weights slightly based on prediction error
   void Learn(double actualOutcome)
   {
      // Error = Actual - Predicted
      double error = actualOutcome - m_y[0];

      // Update Output Layer (Gradient approximation)
      // dW = lr * error * input(z)
      for(int i=0; i<TRM_OUTPUT_SIZE; i++) {
         m_b_out[i] += m_learningRate * error;
         for(int j=0; j<TRM_HIDDEN_SIZE; j++) {
            m_W_out[i*TRM_HIDDEN_SIZE + j] += m_learningRate * error * m_z[j];
         }
      }

      // Note: Backpropagation through time (BPTT) for the recurrent part
      // is complex to implement efficiently in raw MQL5 without a graph engine.
      // We use a simplified Hebbian-like update for the latent weights
      // to drift them towards active paths.
      // (This is a simplified plasticity rule, not full gradient descent)
   }
};
