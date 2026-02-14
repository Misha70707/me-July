//+------------------------------------------------------------------+
//|                                         TinyRecursiveModel.mqh   |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| Tiny Recursive Model (TRM)                                       |
//| Implements a recursive "Think-Loop" using MGU cells to trade     |
//| parameter size for compute time.                                 |
//|                                                                  |
//| ZERO-ALLOCATION COMPLIANT: All buffers pre-allocated.            |
//+------------------------------------------------------------------+
class CTinyRecursiveModel
  {
private:
   // Hyperparameters
   int      m_input_size;     // Size of x
   int      m_hidden_size;    // Size of z (latent state)
   int      m_output_size;    // Size of y (prediction)
   int      m_think_loops;    // Number of recursive reasoning cycles (T)
   int      m_inner_loops;    // Number of inner MGU steps (n)

   // Weights (Flattened)
   double   m_Wf[], m_Uf[], m_bf[];
   double   m_Wh[], m_Uh[], m_bh[];
   double   m_Wy[], m_by[];

   // State Buffers
   double   m_z[];      // Latent state vector (h)
   double   m_y[];      // Prediction vector

   // Temporary Buffers (Pre-allocated for Zero-Allocation)
   double   m_temp_input[]; // Concatenated [x, y]
   double   m_temp_f[];     // Forget gate
   double   m_temp_h_tilde[]; // Candidate state
   double   m_temp_vec_out[]; // Generic vector output buffer
   double   m_temp_Uf_h[];  // Intermediate calculation
   double   m_temp_Uh_fh[]; // Intermediate calculation
   double   m_temp_f_h[];   // Hadamard product f*h

public:
   // Constructor: Pre-allocate all memory
   CTinyRecursiveModel(int inputs, int hidden, int output, int t_loops=3, int n_loops=2)
      : m_input_size(inputs), m_hidden_size(hidden), m_output_size(output),
        m_think_loops(t_loops), m_inner_loops(n_loops)
     {
      // 1. Allocate Weights
      int mgu_input_size = m_input_size + m_output_size;

      ArrayResize(m_Wf, mgu_input_size * m_hidden_size);
      ArrayResize(m_Uf, m_hidden_size * m_hidden_size);
      ArrayResize(m_bf, m_hidden_size);

      ArrayResize(m_Wh, mgu_input_size * m_hidden_size);
      ArrayResize(m_Uh, m_hidden_size * m_hidden_size);
      ArrayResize(m_bh, m_hidden_size);

      ArrayResize(m_Wy, m_output_size * m_hidden_size); // Note dimensions
      ArrayResize(m_by, m_output_size);

      // 2. Initialize Weights
      InitializeWeights();

      // 3. Allocate State Buffers
      ArrayResize(m_z, m_hidden_size);
      ArrayResize(m_y, m_output_size);

      // 4. Allocate Temporary Buffers
      ArrayResize(m_temp_input, mgu_input_size);
      ArrayResize(m_temp_f, m_hidden_size);
      ArrayResize(m_temp_h_tilde, m_hidden_size);
      ArrayResize(m_temp_vec_out, m_hidden_size); // Max size needed
      ArrayResize(m_temp_Uf_h, m_hidden_size);
      ArrayResize(m_temp_Uh_fh, m_hidden_size);
      ArrayResize(m_temp_f_h, m_hidden_size);

      // Initialize state to 0
      ArrayInitialize(m_z, 0.0);
      ArrayInitialize(m_y, 0.0);
     }

   ~CTinyRecursiveModel() { }

   // Core Logic: The "Think-Loop"
   // Returns the final prediction signal (scalar for simplicity, usually y[0])
   double Think(const double &x[])
     {
      // TRM typically maintains state across time steps for market context,
      // but we iterate T times *per bar* to refine the decision.

      // Reset latent state?
      // User says: "stores the reasoning steps".
      // If we want it to be a recurrent model across bars, we don't reset m_z completely.
      // But we might want to decay it or keep it. Let's keep it (Stateful RNN).

      // Outer Loop (T): Refinement Cycles
      for(int t=0; t<m_think_loops; t++)
        {
         // Phase 1: Latent Reasoning (Inner Loop n)
         for(int n=0; n<m_inner_loops; n++)
           {
            MGU_Step(x, m_y, m_z);
           }

         // Phase 2: Answer Refinement
         Dense_Step(m_z, m_y);
        }

      return m_y[0]; // Return the first output dimension as signal
     }

   // Simple Hebbian/Delta Rule Update (Simulated Plasticity)
   // Adapts the Output Layer weights based on prediction error
   void Adapt(double error)
     {
      double learning_rate = 0.01;

      // Update Output Weights: W_new = W_old + lr * error * input(z)
      // m_Wy is [output_size * hidden_size]
      // Since output_size is usually 1 here, we update based on m_z

      for(int r=0; r<m_output_size; r++)
        {
         // If error is scalar, we apply it to the first output, or spread it?
         // For simplicity, we assume error applies to the specific output dimension r.
         // Here we just use the scalar error for all outputs (if >1) as a broadcast.

         int row_offset = r * m_hidden_size;
         for(int c=0; c<m_hidden_size; c++)
           {
            // Delta Rule: dW = lr * err * input
            double delta = learning_rate * error * m_z[c];
            m_Wy[row_offset + c] += delta;

            // Weight Decay / Normalization to prevent explosion
            // m_Wy[row_offset + c] *= 0.999;
           }

         // Update Bias
         m_by[r] += learning_rate * error;
        }
     }

private:
   // MGU Cell Implementation: z_new = MGU([x,y], z_old)
   // All operations use pre-allocated buffers
   void MGU_Step(const double &x[], const double &y_curr[], double &h[])
     {
      // Concatenate Input [x, y] -> m_temp_input
      for(int i=0; i<m_input_size; i++) m_temp_input[i] = x[i];
      for(int i=0; i<m_output_size; i++) m_temp_input[m_input_size+i] = y_curr[i];

      // 1. Forget Gate: f = Sigmoid(Wf*in + Uf*h + bf)
      MatVecMul(m_temp_input, m_Wf, m_temp_f, m_hidden_size); // Wf * in
      MatVecMul(h, m_Uf, m_temp_Uf_h, m_hidden_size);         // Uf * h

      for(int i=0; i<m_hidden_size; i++)
        {
         m_temp_f[i] = Sigmoid(m_temp_f[i] + m_temp_Uf_h[i] + m_bf[i]);
        }

      // 2. Candidate: h_tilde = Tanh(Wh*in + Uh*(f * h) + bh)
      MatVecMul(m_temp_input, m_Wh, m_temp_h_tilde, m_hidden_size); // Wh * in

      // Hadamard f * h
      for(int i=0; i<m_hidden_size; i++) m_temp_f_h[i] = m_temp_f[i] * h[i];

      MatVecMul(m_temp_f_h, m_Uh, m_temp_Uh_fh, m_hidden_size); // Uh * (f*h)

      for(int i=0; i<m_hidden_size; i++)
        {
         double val = m_temp_h_tilde[i] + m_temp_Uh_fh[i] + m_bh[i];
         m_temp_h_tilde[i] = MathTanh(val);
        }

      // 3. Output: h_new = (1-f)*h + f*h_tilde
      for(int i=0; i<m_hidden_size; i++)
        {
         h[i] = (1.0 - m_temp_f[i]) * h[i] + m_temp_f[i] * m_temp_h_tilde[i];
        }
     }

   // Dense Layer: y = Tanh(Wy*z + by)
   void Dense_Step(const double &z[], double &y[])
     {
      MatVecMul(z, m_Wy, y, m_output_size);
      for(int i=0; i<m_output_size; i++)
        {
         y[i] = MathTanh(y[i] + m_by[i]);
        }
     }

   // Helper: Matrix-Vector Multiplication
   // Matrix is flattened row-major: index = row * cols + col
   // Assumes 'out' is pre-allocated
   void MatVecMul(const double &vec[], const double &mat[], double &out[], int out_rows)
     {
      int vec_size = ArraySize(vec);
      // ArrayInitialize(out, 0.0); // Optimization: Do it in loop

      for(int r=0; r<out_rows; r++)
        {
         double sum = 0;
         int row_offset = r * vec_size;
         for(int c=0; c<vec_size; c++)
           {
            sum += vec[c] * mat[row_offset + c];
           }
         out[r] = sum;
        }
     }

   double Sigmoid(double x)
     {
      return 1.0 / (1.0 + MathExp(-x));
     }

   void InitializeWeights()
     {
      int seed = GetTickCount();
      MathSrand(seed);
      InitArrayRandom(m_Wf); InitArrayRandom(m_Uf); InitArrayRandom(m_bf);
      InitArrayRandom(m_Wh); InitArrayRandom(m_Uh); InitArrayRandom(m_bh);
      InitArrayRandom(m_Wy); InitArrayRandom(m_by);
     }

   void InitArrayRandom(double &arr[])
     {
      int size = ArraySize(arr);
      for(int i=0; i<size; i++)
        {
         // Xavier-like initialization (small random values)
         arr[i] = (double)(MathRand() - 16383) / 16383.0 * 0.1;
        }
     }
  };
