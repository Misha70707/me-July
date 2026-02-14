//+------------------------------------------------------------------+
//|                                             TinyRecursiveModel.mqh|
//|                        Copyright 2024, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

// ZENITH ARCHITECTURE: Minimal Gated Unit (MGU) Cell
// Efficient memory usage via pre-allocated buffers.

//+------------------------------------------------------------------+
//| Class CTinyRecursiveModel                                        |
//| Implements a Tiny Recursive Model (TRM) with MGU cells.          |
//| Trades parameter size for compute time (depth).                  |
//+------------------------------------------------------------------+
class CTinyRecursiveModel
  {
private:
   // Hyperparameters
   int               m_input_size;
   int               m_hidden_size;
   int               m_output_size;
   int               m_think_steps;

   // Weights (Simplified flattened arrays for MQL5 efficiency)
   // W_f: Forget Gate Weights
   double            m_W_f[];
   double            m_U_f[];
   double            m_b_f[];

   // W_h: Hidden State Weights
   double            m_W_h[];
   double            m_U_h[];
   double            m_b_h[];

   // Output Layer Weights
   double            m_W_out[];
   double            m_b_out[];

   // Internal State Buffers (allocated once)
   double            m_z[];      // Latent Reasoning Vector
   double            m_y[];      // Prediction Vector (Output)
   double            m_temp_f[]; // Temporary buffer for forget gate
   double            m_temp_h[]; // Temporary buffer for hidden candidate

   //+------------------------------------------------------------------+
   //| Fast Sigmoid Approximation (Performance Critical)                |
   //| 1 / (1 + exp(-x))                                                |
   //+------------------------------------------------------------------+
   double FastSigmoid(double x)
     {
      // Standard sigmoid is slow due to exp().
      // Using standard exp() here for correctness, but could use
      // approximation if extremely tight loop (e.g., lookup table).
      return 1.0 / (1.0 + MathExp(-x));
     }

   //+------------------------------------------------------------------+
   //| Hyperbolic Tangent (Wrapper)                                     |
   //+------------------------------------------------------------------+
   double FastTanh(double x)
     {
      return MathTanh(x);
     }

public:
                     CTinyRecursiveModel() : m_think_steps(6) {}
                    ~CTinyRecursiveModel() {}

   //+------------------------------------------------------------------+
   //| Init                                                             |
   //| Allocates memory and initializes weights (Random for PoC).       |
   //+------------------------------------------------------------------+
   void Init(int input_size, int hidden_size, int output_size, int think_steps=6)
     {
      m_input_size = input_size;
      m_hidden_size = hidden_size;
      m_output_size = output_size;
      m_think_steps = think_steps;

      // Allocate Weights (W: input->hidden, U: hidden->hidden)
      // MGU has 2 gates essentially (Forget, Hidden).
      // Actually standard MGU has 1 gate: Forget (f_t).
      // h_tilde = tanh(W_h * [f_t * h_{t-1}, x_t] + b_h)
      // h_t = (1-f_t)*h_{t-1} + f_t*h_tilde

      int w_size = m_input_size * m_hidden_size;
      int u_size = m_hidden_size * m_hidden_size;
      int b_size = m_hidden_size;

      ArrayResize(m_W_f, w_size); ArrayResize(m_U_f, u_size); ArrayResize(m_b_f, b_size);
      ArrayResize(m_W_h, w_size); ArrayResize(m_U_h, u_size); ArrayResize(m_b_h, b_size);

      ArrayResize(m_W_out, m_hidden_size * m_output_size);
      ArrayResize(m_b_out, m_output_size);

      // Allocate State Buffers
      ArrayResize(m_z, m_hidden_size);
      ArrayResize(m_y, m_output_size);
      ArrayResize(m_temp_f, m_hidden_size);
      ArrayResize(m_temp_h, m_hidden_size);

      // Initialize Weights (Xavier/Random Stub)
      // In a real scenario, load these from a file!
      InitializeRandom(m_W_f); InitializeRandom(m_U_f); InitializeRandom(m_b_f);
      InitializeRandom(m_W_h); InitializeRandom(m_U_h); InitializeRandom(m_b_h);
      InitializeRandom(m_W_out); InitializeRandom(m_b_out);
     }

   void InitializeRandom(double &arr[])
     {
      for(int i=0; i<ArraySize(arr); i++)
         arr[i] = (MathRand() / 32767.0) * 0.1 - 0.05; // Small random weights
     }

   //+------------------------------------------------------------------+
   //| MGU Step (Single Step of Reasoning)                              |
   //| Updates m_z based on input x and previous m_z.                   |
   //+------------------------------------------------------------------+
   void MGU_Step(const double &x[])
     {
      // 1. Calculate Forget Gate f_t
      // f_t = sigmoid(W_f * x + U_f * h_{t-1} + b_f)
      for(int i=0; i<m_hidden_size; i++)
        {
         double sum = m_b_f[i];
         // W_f * x
         for(int j=0; j<m_input_size; j++)
            sum += m_W_f[i*m_input_size + j] * x[j];
         // U_f * h_{t-1} (m_z is h_{t-1})
         for(int k=0; k<m_hidden_size; k++)
            sum += m_U_f[i*m_hidden_size + k] * m_z[k];

         m_temp_f[i] = FastSigmoid(sum);
        }

      // 2. Calculate Candidate Hidden State h_tilde
      // h_tilde = tanh(W_h * x + U_h * (f_t * h_{t-1}) + b_h)
      // Note: MGU variation often applies f_t to h_{t-1} before matrix mult.
      for(int i=0; i<m_hidden_size; i++)
        {
         double sum = m_b_h[i];
         // W_h * x
         for(int j=0; j<m_input_size; j++)
            sum += m_W_h[i*m_input_size + j] * x[j];
         // U_h * (f_t * h_{t-1})
         for(int k=0; k<m_hidden_size; k++)
            sum += m_U_h[i*m_hidden_size + k] * (m_temp_f[k] * m_z[k]);

         m_temp_h[i] = FastTanh(sum);
        }

      // 3. Update Hidden State h_t (m_z)
      // h_t = (1 - f_t) * h_{t-1} + f_t * h_tilde
      for(int i=0; i<m_hidden_size; i++)
        {
         m_z[i] = (1.0 - m_temp_f[i]) * m_z[i] + m_temp_f[i] * m_temp_h[i];
        }
     }

   //+------------------------------------------------------------------+
   //| Predict (Orchestrator)                                           |
   //| Executes the Think-Loop (Phase 1 & 2).                           |
   //+------------------------------------------------------------------+
   void Predict(const double &x[], double &y_out[])
     {
      // Reset Latent State for new prediction?
      // TRM often carries state, but for a fresh "Think" on new bar, maybe reset or keep?
      // Keeping it allows "long-term memory" across bars.
      // For now, we assume continuous state (stateful RNN).

      // Phase 1: Latent Reasoning (Think Loop)
      // Iterate 'm_think_steps' times to refine z
      for(int step=0; step<m_think_steps; step++)
        {
         MGU_Step(x);
        }

      // Phase 2: Answer Refinement (Readout)
      // Project z to y (Linear + Sigmoid/Softmax)
      // y = W_out * z + b_out
      for(int i=0; i<m_output_size; i++)
        {
         double sum = m_b_out[i];
         for(int j=0; j<m_hidden_size; j++)
            sum += m_W_out[i*m_hidden_size + j] * m_z[j];

         m_y[i] = FastSigmoid(sum); // Assume classification (0..1)
        }

      // Copy result to output
      if(ArraySize(y_out) != m_output_size)
         ArrayResize(y_out, m_output_size);

      ArrayCopy(y_out, m_y);
     }
  };
