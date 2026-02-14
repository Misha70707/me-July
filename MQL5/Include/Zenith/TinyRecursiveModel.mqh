//+------------------------------------------------------------------+
//|                                           TinyRecursiveModel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//------------------------------------------------------------------
// Tiny Recursive Model (TRM) Implementation
// Architecture: Minimal Gated Unit (MGU) for Reasoning Loop
// Strategy: Trade parameter size for compute time via recursion
//------------------------------------------------------------------

enum ENUM_ACTIVATION
  {
   ACT_SIGMOID,
   ACT_TANH,
   ACT_RELU,
   ACT_LINEAR
  };

struct TRM_State
  {
   double            z[]; // Latent Reasoning/Context Vector
   double            y[]; // Prediction/Output Vector

   void Resize(int z_size, int y_size)
     {
      ArrayResize(z, z_size);
      ArrayResize(y, y_size);
      ArrayInitialize(z, 0.0);
      ArrayInitialize(y, 0.0);
     }
  };

class CTinyRecursiveModel
  {
private:
   // Model Configuration
   int               m_input_size;     // Size of x (Market Features)
   int               m_hidden_size;    // Size of z (Latent Space)
   int               m_output_size;    // Size of y (Prediction)

   int               m_reasoning_steps; // Number of inner loop iterations (n)
   int               m_refinement_steps;// Number of outer loop iterations (T)

   // Weights (Simplified for MGU: W_f, W_c)
   // Concatenated input size for MGU = input_size + output_size + hidden_size
   // But standard MGU takes [input, hidden]. Here input is [x, y].
   // So Effective Input Size = m_input_size + m_output_size.

   // MGU Forget Gate Weights: [HiddenSize x (InputSize + OutputSize + HiddenSize)]
   double            m_W_f[];
   double            m_b_f[];

   // MGU Candidate Gate Weights: [HiddenSize x (InputSize + OutputSize + HiddenSize)]
   double            m_W_c[];
   double            m_b_c[];

   // Refinement Weights (Output Head): [OutputSize x HiddenSize]
   double            m_W_y[];
   double            m_b_y[];

   // Helper: Random Initialization
   void InitRandom(double &w[], int size, double scale=0.1)
     {
      ArrayResize(w, size);
      for(int i=0; i<size; i++)
         w[i] = (MathRand()/32767.0 - 0.5) * 2.0 * scale;
     }

   // Helper: Activation Functions
   double Sigmoid(double x) { return 1.0 / (1.0 + MathExp(-x)); }
   double Tanh(double x) { return MathTanh(x); }
   double ReLU(double x) { return x > 0 ? x : 0; }

   // Helper: Matrix-Vector Multiplication
   // y = W * x + b
   // W is flattened [rows * cols], x is [cols], y is [rows]
   void MatVecMul(const double &W[], const double &vec[], const double &b[], double &out[], int rows, int cols, ENUM_ACTIVATION act)
     {
      ArrayResize(out, rows);
      for(int i=0; i<rows; i++)
        {
         double sum = b[i];
         for(int j=0; j<cols; j++)
           {
            sum += W[i*cols + j] * vec[j];
           }

         switch(act)
           {
            case ACT_SIGMOID: out[i] = Sigmoid(sum); break;
            case ACT_TANH:    out[i] = Tanh(sum); break;
            case ACT_RELU:    out[i] = ReLU(sum); break;
            case ACT_LINEAR:  out[i] = sum; break;
           }
        }
     }

public:
                     CTinyRecursiveModel();
                    ~CTinyRecursiveModel();

   // Initialization
   void              Init(int n_in, int n_hidden, int n_out, int n_reasoning=6, int n_refine=2);

   // Core TRM Forward Pass
   // x: Market Features
   // state: Holds z and y (passed by reference to maintain state if needed, or reset)
   void              Think(const double &x[], TRM_State &state);

   // Quantization Placeholder (Simulated INT8 conversion)
   double            Quantize(double val) { return round(val * 127.0) / 127.0; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTinyRecursiveModel::CTinyRecursiveModel()
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTinyRecursiveModel::~CTinyRecursiveModel()
  {
  }
//+------------------------------------------------------------------+
//| Initialize Model Architecture                                    |
//+------------------------------------------------------------------+
void CTinyRecursiveModel::Init(int n_in, int n_hidden, int n_out, int n_reasoning, int n_refine)
  {
   m_input_size = n_in;
   m_hidden_size = n_hidden;
   m_output_size = n_out;
   m_reasoning_steps = n_reasoning;
   m_refinement_steps = n_refine;

   // Total effective input for MGU logic: x + y + z_prev
   int total_input_dim = m_input_size + m_output_size + m_hidden_size;

   // Initialize Weights (MGU has 2 sets of weights for minimal gating)
   // W_f: Forget Gate
   InitRandom(m_W_f, m_hidden_size * total_input_dim);
   InitRandom(m_b_f, m_hidden_size);

   // W_c: Candidate Gate
   InitRandom(m_W_c, m_hidden_size * total_input_dim);
   InitRandom(m_b_c, m_hidden_size);

   // W_y: Output Refinement
   InitRandom(m_W_y, m_output_size * m_hidden_size);
   InitRandom(m_b_y, m_output_size);
  }
//+------------------------------------------------------------------+
//| The "Think-Loop": Recursive Reasoning and Refinement             |
//+------------------------------------------------------------------+
void CTinyRecursiveModel::Think(const double &x[], TRM_State &state)
  {
   // Validate Input
   if(ArraySize(x) != m_input_size)
     {
      Print("TRM Error: Input size mismatch. Expected ", m_input_size, ", got ", ArraySize(x));
      return;
     }

   // Initialize State if empty
   if(ArraySize(state.z) != m_hidden_size || ArraySize(state.y) != m_output_size)
     {
      state.Resize(m_hidden_size, m_output_size);
     }

   // Temporary buffers
   double combined_input[];
   int total_dim = m_input_size + m_output_size + m_hidden_size;
   ArrayResize(combined_input, total_dim);

   double f_gate[]; // Forget gate output
   double c_gate[]; // Candidate gate output
   double z_new[];  // New latent state
   ArrayResize(f_gate, m_hidden_size);
   ArrayResize(c_gate, m_hidden_size);
   ArrayResize(z_new, m_hidden_size);

   // --- Outer Loop: Answer Refinement (Phase 2) ---
   for(int t_outer = 0; t_outer < m_refinement_steps; t_outer++)
     {
      // --- Inner Loop: Latent Reasoning (Phase 1) ---
      for(int t_inner = 0; t_inner < m_reasoning_steps; t_inner++)
        {
         // 1. Prepare Combined Input: [x, y, z_prev]
         int idx = 0;
         for(int i=0; i<m_input_size; i++) combined_input[idx++] = x[i];
         for(int i=0; i<m_output_size; i++) combined_input[idx++] = state.y[i]; // Current guess
         for(int i=0; i<m_hidden_size; i++) combined_input[idx++] = state.z[i]; // Current reasoning

         // 2. MGU Logic

         // Forget Gate: f = Sigmoid(W_f * [x,y,z] + b_f)
         MatVecMul(m_W_f, combined_input, m_b_f, f_gate, m_hidden_size, total_dim, ACT_SIGMOID);

         // Candidate Input: W_c * [x,y, (f * z_prev)] + b_c
         // We need to modify the combined input specifically for the candidate calculation
         // where z component is modulated by the forget gate
         double cand_input[];
         ArrayCopy(cand_input, combined_input); // Copy x and y parts
         // Modulate z part
         int z_start = m_input_size + m_output_size;
         for(int i=0; i<m_hidden_size; i++)
            cand_input[z_start + i] = f_gate[i] * state.z[i];

         // Candidate: c = Tanh(W_c * modified_input + b_c)
         MatVecMul(m_W_c, cand_input, m_b_c, c_gate, m_hidden_size, total_dim, ACT_TANH);

         // Update State: z_new = (1-f)*z_prev + f*c
         // Note: Standard MGU/GRU usually uses z as update gate.
         // Here we use 'f' as the mixing factor (similar to Update Gate in GRU).
         for(int i=0; i<m_hidden_size; i++)
           {
            state.z[i] = (1.0 - f_gate[i]) * state.z[i] + f_gate[i] * c_gate[i];
            // Simulate Quantization (INT8 effect on state)
            state.z[i] = Quantize(state.z[i]);
           }
        } // End Inner Loop

      // --- Refinement Step ---
      // Update y based on refined z
      // y = Tanh(W_y * z + b_y)
      MatVecMul(m_W_y, state.z, m_b_y, state.y, m_output_size, m_hidden_size, ACT_TANH);

     } // End Outer Loop
  }
