//+------------------------------------------------------------------+
//|                                           TinyRecursiveModel.mqh |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

#include <Math\Stat\Math.mqh>

//+------------------------------------------------------------------+
//| Tiny Recursive Model (TRM) Implementation                        |
//| Based on the concept of iterating through a small network        |
//| to refine reasoning (z) and prediction (y).                      |
//| Uses Minimal Gated Unit (MGU) cells for efficiency.              |
//+------------------------------------------------------------------+
class CTinyRecursiveModel
  {
private:
   // Dimensions
   int               m_input_dim;
   int               m_hidden_dim; // Size of Z
   int               m_output_dim; // Size of Y

   // Weights for Phase 1: Update Z (Latent Reasoning)
   // Input to Z gate (W_f_z, W_h_z) - dimension: hidden_dim x (input_dim + output_dim)
   matrix            m_W_f_z;
   matrix            m_W_h_z;
   // Recurrent Z to Z (U_f_z, U_h_z) - dimension: hidden_dim x hidden_dim
   matrix            m_U_f_z;
   matrix            m_U_h_z;
   // Biases for Z
   vector            m_b_f_z;
   vector            m_b_h_z;

   // Weights for Phase 2: Update Y (Answer Refinement)
   // Input (Z) to Y gate (W_f_y, W_h_y) - dimension: output_dim x hidden_dim
   matrix            m_W_f_y;
   matrix            m_W_h_y;
   // Recurrent Y to Y (U_f_y, U_h_y) - dimension: output_dim x output_dim
   matrix            m_U_f_y;
   matrix            m_U_h_y;
   // Biases for Y
   vector            m_b_f_y;
   vector            m_b_h_y;

   // State Vectors
   vector            m_z; // Latent Reasoning State
   vector            m_y; // Prediction State

public:
                     CTinyRecursiveModel();
                    ~CTinyRecursiveModel();

   // Initialize the model with specific dimensions
   void              Init(int input_size, int hidden_size, int output_size);

   // The Core "Think-Loop"
   // Returns the final prediction vector y
   vector            Think(const vector &input_x, int recursion_cycles=2, int reasoning_steps=6);

   // Random initialization for demo purposes (Xavier/Glorot)
   void              RandomizeWeights();

private:
   // Minimal Gated Unit (MGU) Cell
   // h_t = MGU(x_t, h_t-1)
   vector            MGU_Cell(const vector &x_t, const vector &h_prev,
                              const matrix &W_f, const matrix &U_f, const vector &b_f,
                              const matrix &W_h, const matrix &U_h, const vector &b_h);

   // Activation Functions
   vector            Sigmoid(const vector &v);
   vector            Tanh(const vector &v);
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
//| Initialize Model Dimensions and Buffers                          |
//+------------------------------------------------------------------+
void CTinyRecursiveModel::Init(int input_size, int hidden_size, int output_size)
  {
   m_input_dim = input_size;
   m_hidden_dim = hidden_size;
   m_output_dim = output_size;

   // Phase 1 (Update Z): Input is concatenation of x and y
   int z_input_size = input_size + output_size;

   // Resize Matrices for Z
   m_W_f_z.Resize(hidden_size, z_input_size);
   m_W_h_z.Resize(hidden_size, z_input_size);
   m_U_f_z.Resize(hidden_size, hidden_size);
   m_U_h_z.Resize(hidden_size, hidden_size);
   m_b_f_z.Resize(hidden_size);
   m_b_h_z.Resize(hidden_size);

   // Phase 2 (Update Y): Input is Z
   int y_input_size = hidden_size;

   // Resize Matrices for Y
   m_W_f_y.Resize(output_size, y_input_size);
   m_W_h_y.Resize(output_size, y_input_size);
   m_U_f_y.Resize(output_size, output_size);
   m_U_h_y.Resize(output_size, output_size);
   m_b_f_y.Resize(output_size);
   m_b_h_y.Resize(output_size);

   // Initialize State
   m_z.Resize(hidden_size);
   m_y.Resize(output_size);
   m_z.Fill(0.0);
   m_y.Fill(0.0); // Initial guess 0 (Hold/Neutral)
  }
//+------------------------------------------------------------------+
//| Randomize Weights (Xavier/Glorot Initialization)                 |
//+------------------------------------------------------------------+
void CTinyRecursiveModel::RandomizeWeights()
  {
   MathSrand(GetTickCount());
   // Simplified initialization: Uniform random [-0.1, 0.1] for demo stability
   // In production, load pre-trained weights

   auto InitMatrix = [&](matrix &m) {
      for(int r=0; r<m.Rows(); r++)
         for(int c=0; c<m.Cols(); c++)
            m[r][c] = (double)(MathRand() - 16383) / 16383.0 * 0.1;
   };

   auto InitVector = [&](vector &v) {
      for(int i=0; i<v.Size(); i++)
         v[i] = (double)(MathRand() - 16383) / 16383.0 * 0.01; // Small bias
   };

   InitMatrix(m_W_f_z); InitMatrix(m_W_h_z);
   InitMatrix(m_U_f_z); InitMatrix(m_U_h_z);
   InitVector(m_b_f_z); InitVector(m_b_h_z);

   InitMatrix(m_W_f_y); InitMatrix(m_W_h_y);
   InitMatrix(m_U_f_y); InitMatrix(m_U_h_y);
   InitVector(m_b_f_y); InitVector(m_b_h_y);
  }
//+------------------------------------------------------------------+
//| Sigmoid Activation Function                                      |
//+------------------------------------------------------------------+
vector CTinyRecursiveModel::Sigmoid(const vector &v)
  {
   vector res = v;
   for(int i=0; i<res.Size(); i++)
      res[i] = 1.0 / (1.0 + MathExp(-res[i]));
   return res;
  }
//+------------------------------------------------------------------+
//| Tanh Activation Function                                         |
//+------------------------------------------------------------------+
vector CTinyRecursiveModel::Tanh(const vector &v)
  {
   vector res = v;
   for(int i=0; i<res.Size(); i++)
      res[i] = MathTanh(res[i]);
   return res;
  }
//+------------------------------------------------------------------+
//| MGU Cell Logic                                                   |
//| f_t = sigmoid(W_f*x + U_f*h_prev + b_f)                          |
//| h_tilde = tanh(W_h*x + U_h*(f_t * h_prev) + b_h)                 |
//| h_t = (1-f_t)*h_prev + f_t*h_tilde                               |
//+------------------------------------------------------------------+
vector CTinyRecursiveModel::MGU_Cell(const vector &x_t, const vector &h_prev,
                                     const matrix &W_f, const matrix &U_f, const vector &b_f,
                                     const matrix &W_h, const matrix &U_h, const vector &b_h)
  {
   // 1. Forget Gate (f_t)
   // W_f * x_t
   vector wx = W_f.MatMul(x_t);
   // U_f * h_prev
   vector uh = U_f.MatMul(h_prev);

   vector f_t = Sigmoid(wx + uh + b_f);

   // 2. Candidate Activation (h_tilde)
   // f_t * h_prev (element-wise)
   vector f_h = f_t * h_prev;
   // U_h * (f_t * h_prev)
   vector uh_cand = U_h.MatMul(f_h);
   // W_h * x_t
   vector wx_cand = W_h.MatMul(x_t);

   vector h_tilde = Tanh(wx_cand + uh_cand + b_h);

   // 3. Final Output (h_t)
   // (1 - f_t) * h_prev
   vector one_minus_f = 1.0 - f_t;
   vector term1 = one_minus_f * h_prev;
   // f_t * h_tilde
   vector term2 = f_t * h_tilde;

   return term1 + term2;
  }
//+------------------------------------------------------------------+
//| The "Think-Loop"                                                 |
//+------------------------------------------------------------------+
vector CTinyRecursiveModel::Think(const vector &input_x, int recursion_cycles=2, int reasoning_steps=6)
  {
   // Reset internal state for new inference?
   // TRM usually keeps state between ticks if it's a sequence model,
   // but "Reasoning" z is usually reset per inference to "think" about *this* input.
   // Let's reset Z to 0. Y keeps previous guess?
   // User: "initially random or zero" for Y. But usually in trading we might want continuity.
   // Let's reset Z, keep Y (or reset Y if it's a fresh prediction).
   // For safety, let's reset Z.
   m_z.Fill(0.0);
   // m_y.Fill(0.0); // Keeping Y as "previous guess" is key to the recursive idea.

   for(int t=0; t<recursion_cycles; t++)
     {
      // Phase 1: Latent Reasoning (Update Z multiple times)
      // Input to Z is concatenation of X and current Y
      vector z_input;
      z_input.Resize(m_input_dim + m_output_dim);

      // Concat: [x, y]
      for(int i=0; i<m_input_dim; i++) z_input[i] = input_x[i];
      for(int i=0; i<m_output_dim; i++) z_input[m_input_dim + i] = m_y[i];

      for(int n=0; n<reasoning_steps; n++)
        {
         m_z = MGU_Cell(z_input, m_z, m_W_f_z, m_U_f_z, m_b_f_z, m_W_h_z, m_U_h_z, m_b_h_z);
        }

      // Phase 2: Answer Refinement (Update Y once)
      // Input to Y is Z
      m_y = MGU_Cell(m_z, m_y, m_W_f_y, m_U_f_y, m_b_f_y, m_W_h_y, m_U_h_y, m_b_h_y);
     }

   return m_y;
  }
