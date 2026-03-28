//+------------------------------------------------------------------+
//|                                           TinyRecursiveModel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Class CTinyRecursiveModel                                        |
//| Implements the Tiny Recursive Model (TRM) architecture.          |
//| Concept: Trades parameter size for compute time via recursion.     |
//| Core Unit: Minimal Gated Unit (MGU).                             |
//+------------------------------------------------------------------+
class CTinyRecursiveModel
  {
private:
   // Model Configuration
   int               m_input_dim;      // Size of input vector x
   int               m_hidden_dim;     // Size of latent vector z (and y embedding)
   int               m_reasoning_steps;// Number of inner reasoning loops (N)
   int               m_refinement_cycles;// Number of outer refinement loops (T)

   // MGU Weights for Reasoning Phase (Input: [x, y], State: z)
   matrix            m_Wf_reasoning, m_Uf_reasoning; // Forget gate weights
   vector            m_bf_reasoning;                 // Forget gate bias
   matrix            m_Wh_reasoning, m_Uh_reasoning; // Candidate weights
   vector            m_bh_reasoning;                 // Candidate bias

   // MGU Weights for Refinement Phase (Input: z, State: y)
   matrix            m_Wf_refine, m_Uf_refine;       // Forget gate weights
   vector            m_bf_refine;                    // Forget gate bias
   matrix            m_Wh_refine, m_Uh_refine;       // Candidate weights
   vector            m_bh_refine;                    // Candidate bias

   // Final Projection Weights (y -> signal)
   matrix            m_W_out;
   vector            m_b_out;

   // Activation Functions
   double Sigmoid(double x) { return 1.0 / (1.0 + MathExp(-x)); }
   double Tanh(double x) { return MathTanh(x); }

   // Vectorized Activations (Helper)
   vector ActivateSigmoid(vector &v)
     {
      vector res = v;
      for(int i=0; i<res.Size(); i++) res[i] = Sigmoid(res[i]);
      return res;
     }
   vector ActivateTanh(vector &v)
     {
      vector res = v;
      for(int i=0; i<res.Size(); i++) res[i] = Tanh(res[i]);
      return res;
     }

   // Helper: Element-wise Vector Multiplication
   vector ElementWiseMul(vector &v1, vector &v2)
     {
      vector res = v1;
      if(v1.Size() != v2.Size()) return res;
      for(int i=0; i<res.Size(); i++) res[i] = v1[i] * v2[i];
      return res;
     }

   // Minimal Gated Unit (MGU) Cell
   // Input: x_t (current input), h_prev (previous hidden state)
   // Weights: Wf, Uf, bf (Forget), Wh, Uh, bh (Candidate)
   // Returns: h_t (new hidden state)
   vector MGU_Cell(vector &x_t, vector &h_prev,
                  matrix &Wf, matrix &Uf, vector &bf,
                  matrix &Wh, matrix &Uh, vector &bh)
     {
      // 1. Forget Gate: f_t = Sigmoid(Wf * x_t + Uf * h_prev + bf)
      vector f_gate = Wf.MatMul(x_t) + Uf.MatMul(h_prev) + bf;
      f_gate = ActivateSigmoid(f_gate);

      // 2. Candidate State: h_hat = Tanh(Wh * x_t + Uh * (f_gate * h_prev) + bh)
      vector f_h_prev = ElementWiseMul(f_gate, h_prev);
      vector h_hat = Wh.MatMul(x_t) + Uh.MatMul(f_h_prev) + bh;
      h_hat = ActivateTanh(h_hat);

      // 3. Final State: h_t = (1 - f_gate) * h_prev + f_gate * h_hat
      vector one_minus_f;
      one_minus_f.Resize(f_gate.Size());
      for(int i=0; i<f_gate.Size(); i++) one_minus_f[i] = 1.0 - f_gate[i];

      vector term1 = ElementWiseMul(one_minus_f, h_prev);
      vector term2 = ElementWiseMul(f_gate, h_hat);

      vector h_t = term1 + term2;

      return h_t;
     }

   // Random Initialization Helper
   void InitMatrixRandom(matrix &m, int rows, int cols, double scale=0.1)
     {
      m.Resize(rows, cols);
      for(int r=0; r<rows; r++)
         for(int c=0; c<cols; c++)
            m[r][c] = (MathRand()/32767.0 - 0.5) * 2.0 * scale; // Uniform [-scale, scale]
     }
   void InitVectorRandom(vector &v, int size, double scale=0.1)
     {
      v.Resize(size);
      for(int i=0; i<size; i++)
         v[i] = (MathRand()/32767.0 - 0.5) * 2.0 * scale;
     }

public:
   CTinyRecursiveModel(void) {}
   ~CTinyRecursiveModel(void) {}

   // Initialize the Model Structure
   void Init(int input_dim, int hidden_dim, int reasoning_steps=6, int refinement_cycles=2)
     {
      m_input_dim = input_dim;
      m_hidden_dim = hidden_dim;
      m_reasoning_steps = reasoning_steps;
      m_refinement_cycles = refinement_cycles;

      MathSrand(GetTickCount()); // Seed RNG

      // --- Reasoning Phase Weights (Input: [x, y], State: z) ---
      // Input size to reasoning MGU is size(x) + size(y). Assume size(y) == hidden_dim.
      int total_input_reasoning = m_input_dim + m_hidden_dim;

      InitMatrixRandom(m_Wf_reasoning, m_hidden_dim, total_input_reasoning);
      InitMatrixRandom(m_Uf_reasoning, m_hidden_dim, m_hidden_dim);
      InitVectorRandom(m_bf_reasoning, m_hidden_dim);

      InitMatrixRandom(m_Wh_reasoning, m_hidden_dim, total_input_reasoning);
      InitMatrixRandom(m_Uh_reasoning, m_hidden_dim, m_hidden_dim);
      InitVectorRandom(m_bh_reasoning, m_hidden_dim);

      // --- Refinement Phase Weights (Input: z, State: y) ---
      // Input size to refinement MGU is size(z). Assume size(z) == hidden_dim.
      int total_input_refine = m_hidden_dim;

      InitMatrixRandom(m_Wf_refine, m_hidden_dim, total_input_refine);
      InitMatrixRandom(m_Uf_refine, m_hidden_dim, m_hidden_dim);
      InitVectorRandom(m_bf_refine, m_hidden_dim);

      InitMatrixRandom(m_Wh_refine, m_hidden_dim, total_input_refine);
      InitMatrixRandom(m_Uh_refine, m_hidden_dim, m_hidden_dim);
      InitVectorRandom(m_bh_refine, m_hidden_dim);

      // --- Output Projection (y -> 1 scalar signal) ---
      InitMatrixRandom(m_W_out, 1, m_hidden_dim);
      InitVectorRandom(m_b_out, 1);
     }

   // Concatenate two vectors
   vector Concat(vector &v1, vector &v2)
     {
      vector res;
      res.Resize(v1.Size() + v2.Size());
      for(int i=0; i<v1.Size(); i++) res[i] = v1[i];
      for(int i=0; i<v2.Size(); i++) res[v1.Size()+i] = v2[i];
      return res;
     }

   // Forward Pass: Predict Signal
   // Returns: Signal value (-1.0 to 1.0)
   double Predict(vector &x)
     {
      if(x.Size() != m_input_dim)
        {
         Print("Error: Input vector size mismatch. Expected ", m_input_dim, ", got ", x.Size());
         return 0.0;
        }

      // Initialize State Vectors
      vector z; z.Resize(m_hidden_dim); z.Fill(0.0); // Latent Reasoning State
      vector y; y.Resize(m_hidden_dim); y.Fill(0.0); // Current Prediction State (Embedding)

      // --- The Recursive Loop ---
      for(int t=0; t<m_refinement_cycles; t++)
        {
         // Phase 1: Latent Reasoning (Update z)
         // Loops 'reasoning_steps' times to refine internal logic
         for(int n=0; n<m_reasoning_steps; n++)
           {
            // Input to Reasoning MGU is concatenation of Market Data (x) and Current Prediction (y)
            vector combined_input = Concat(x, y);
            z = MGU_Cell(combined_input, z,
                        m_Wf_reasoning, m_Uf_reasoning, m_bf_reasoning,
                        m_Wh_reasoning, m_Uh_reasoning, m_bh_reasoning);
           }

         // Phase 2: Answer Refinement (Update y)
         // Uses updated reasoning (z) to refine the prediction state (y)
         // Input to Refinement MGU is Reasoning State (z)
         y = MGU_Cell(z, y,
                     m_Wf_refine, m_Uf_refine, m_bf_refine,
                     m_Wh_refine, m_Uh_refine, m_bh_refine);
        }

      // Final Output Projection
      vector out = m_W_out.MatMul(y) + m_b_out;

      // Tanh activation for final signal (-1 to 1)
      return Tanh(out[0]);
     }

   // Get current reasoning state magnitude (for visualization/debugging)
   double GetReasoningMagnitude()
     {
      // Simple L2 norm proxy
      // Since we don't store persistent state outside Predict, this returns 0 unless called during execution.
      // In a real implementation, we might want to store 'z' as a member to inspect it later.
      return 0.0;
     }
  };
//+------------------------------------------------------------------+
