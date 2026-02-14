//+------------------------------------------------------------------+
//|                                        TinyRecursiveUnit.mqh    |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Using matrixf (float 32-bit) for efficient memory/compute (Simulated Quantization)
// MGU (Minimal Gated Unit) Implementation

// Ensure types are available
#ifndef vectorf
   #define vectorf vector<float>
#endif
#ifndef matrixf
   #define matrixf matrix<float>
#endif

class CMGU {
private:
    matrixf Wf, Uf; // Forget gate weights
    vectorf bf;     // Forget gate bias
    matrixf Wh, Uh; // Hidden state weights
    vectorf bh;     // Hidden state bias

    int input_size;
    int hidden_size;
    bool initialized;

public:
    CMGU() : initialized(false) {}

    void Init(int inp, int hid) {
        input_size = inp;
        hidden_size = hid;

        // Random Initialization (Xavier/Glorot-like for simulation)
        float scale = sqrt(2.0f / (float)(inp + hid));

        Wf.Resize(hidden_size, input_size); SetRandom(Wf, -scale, scale);
        Uf.Resize(hidden_size, hidden_size); SetRandom(Uf, -scale, scale);
        bf.Resize(hidden_size); bf.Fill(0.0f); // Bias init to 0

        Wh.Resize(hidden_size, input_size); SetRandom(Wh, -scale, scale);
        Uh.Resize(hidden_size, hidden_size); SetRandom(Uh, -scale, scale);
        bh.Resize(hidden_size); bh.Fill(0.0f);

        initialized = true;
    }

    void SetRandom(matrixf &m, float min, float max) {
        for(ulong r=0; r<m.Rows(); r++)
            for(ulong c=0; c<m.Cols(); c++)
                m[r][c] = min + ((float)MathRand()/32767.0f) * (max - min);
    }

    // Forward Pass: h_t = MGU(x_t, h_{t-1})
    // f_t = sigmoid(Wf*x + Uf*h_prev + bf)
    // h_tilde = tanh(Wh*x + Uh*(f*h_prev) + bh)
    // h_new = (1-f)*h_prev + f*h_tilde
    vectorf Forward(vectorf &x, vectorf &h_prev) {
        if(!initialized) return h_prev;

        // 1. Forget Gate (f)
        vectorf f = Wf.MatMul(x) + Uf.MatMul(h_prev) + bf;
        f = Sigmoid(f);

        // 2. Candidate State (h_tilde)
        vectorf fh = Hadamard(f, h_prev); // Element-wise multiplication
        vectorf h_tilde = Wh.MatMul(x) + Uh.MatMul(fh) + bh;
        h_tilde = Tanh(h_tilde);

        // 3. Final State
        // h_new = (1-f) * h_prev + f * h_tilde
        vectorf ones(hidden_size); ones.Fill(1.0f);
        vectorf forget_part = ones - f;
        vectorf term1 = Hadamard(forget_part, h_prev);
        vectorf term2 = Hadamard(f, h_tilde);

        vectorf h_new = term1 + term2;

        return h_new;
    }

    // Element-wise Multiplication (Hadamard Product)
    vectorf Hadamard(vectorf &v1, vectorf &v2) {
        vectorf res(v1.Size());
        for(ulong i=0; i<v1.Size(); i++) res[i] = v1[i] * v2[i];
        return res;
    }

    // Activation Helpers (vectorf doesn't always have .Activation() in older builds)
    vectorf Sigmoid(vectorf &v) {
        vectorf res = v;
        for(ulong i=0; i<res.Size(); i++) res[i] = 1.0f / (1.0f + exp(-res[i]));
        return res;
    }

    vectorf Tanh(vectorf &v) {
        vectorf res = v;
        for(ulong i=0; i<res.Size(); i++) res[i] = tanh(res[i]);
        return res;
    }
};

class CTRM {
private:
    CMGU reasoning_unit;  // For updating z (Latent Reasoning)
    CMGU refinement_unit; // For updating y (Answer Refinement)

    int input_dim;
    int latent_dim;
    int output_dim;

    int n_reasoning_steps; // Inner loop (Thinking depth)
    int T_cycles;          // Outer loop (Refinement cycles)

public:
    void Init(int inp, int latent, int out, int n_steps=6, int t_cycles=2) {
        input_dim = inp;
        latent_dim = latent;
        output_dim = out;
        n_reasoning_steps = n_steps;
        T_cycles = t_cycles;

        // Reasoning Unit:
        // Inputs: Market Data (x) + Current Guess (y)
        // Hidden State: Latent Reasoning (z)
        reasoning_unit.Init(input_dim + output_dim, latent_dim);

        // Refinement Unit:
        // Inputs: Latent Reasoning (z)
        // Hidden State: Current Guess (y) -> This effectively updates y based on z
        refinement_unit.Init(latent_dim, output_dim);
    }

    // The "Think" Loop
    vectorf Think(vectorf &x) {
        // Initialize Prediction (y) and Latent State (z)
        vectorf y(output_dim); y.Fill(0.0f); // Start with neutral guess
        vectorf z(latent_dim); z.Fill(0.0f); // Empty scratchpad

        // Loop T times (Outer Cycle)
        vectorf combined_input(input_dim + output_dim);

        // Pre-fill static input part (x)
        for(int k=0; k<input_dim; k++) combined_input[k] = x[k];

        for(int t=0; t<T_cycles; t++) {
            // Update dynamic input part (y) - Only this changes per cycle
            for(int k=0; k<output_dim; k++) combined_input[input_dim+k] = y[k];

            // Phase A: Latent Reasoning (Inner Loop)
            // "Think deeper" by recycling z multiple times against x and y (which are constant in this phase)
            for(int i=0; i<n_reasoning_steps; i++) {
                // Update z based on static input context and dynamic hidden state z
                z = reasoning_unit.Forward(combined_input, z);
            }

            // Phase B: Answer Refinement (Once per cycle)
            // Update y using the refined reasoning z
            y = refinement_unit.Forward(z, y);
        }

        return y;
    }
};
