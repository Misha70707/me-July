//+------------------------------------------------------------------+
//|                      Benchmark_ZeroAllocation.mq5               |
//|               Benchmark for Dynamic Allocation vs Pre-Allocated |
//+------------------------------------------------------------------+
#property copyright "Neuroplastic Trading Framework"
#property version   "1.00"
#property script_show_inputs

input int Iterations = 100000; // Number of iterations to simulate ticks

//+------------------------------------------------------------------+
//| Benchmark Class                                                 |
//+------------------------------------------------------------------+
class CBenchmark {
private:
   double m_buffer1[];
   double m_buffer2[];
   double m_buffer3[];
   double m_buffer4[];

public:
   CBenchmark() {
      ArrayResize(m_buffer1, 10);
      ArrayResize(m_buffer2, 10);
      ArrayResize(m_buffer3, 10);
      ArrayResize(m_buffer4, 10);
   }

   // Simulate logic using local (dynamic) allocation
   void TestAllocation() {
      double local1[];
      double local2[];
      double local3[];
      double local4[];

      ArrayResize(local1, 10);
      ArrayResize(local2, 10);
      ArrayResize(local3, 10);
      ArrayResize(local4, 10);

      for(int i=0; i<10; i++) {
         local1[i] = i;
         local2[i] = i*2;
         local3[i] = i*3;
         local4[i] = i*4;
      }
   }

   // Simulate logic using member (pre-allocated) buffers
   void TestPreAllocated() {
      // Buffers already sized in constructor
      for(int i=0; i<10; i++) {
         m_buffer1[i] = i;
         m_buffer2[i] = i*2;
         m_buffer3[i] = i*3;
         m_buffer4[i] = i*4;
      }
   }
};

//+------------------------------------------------------------------+
//| Script program start function                                   |
//+------------------------------------------------------------------+
void OnStart() {
   CBenchmark bench;
   ulong start, end;

   Print("Starting Benchmark with ", Iterations, " iterations...");

   // Test 1: Dynamic Allocation
   start = GetMicrosecondCount();
   for(int i=0; i<Iterations; i++) {
      bench.TestAllocation();
   }
   end = GetMicrosecondCount();
   ulong timeAlloc = end - start;
   Print("Dynamic Allocation Time: ", timeAlloc, " us");

   // Test 2: Pre-Allocated
   start = GetMicrosecondCount();
   for(int i=0; i<Iterations; i++) {
      bench.TestPreAllocated();
   }
   end = GetMicrosecondCount();
   ulong timePreAlloc = end - start;
   Print("Pre-Allocated Time:      ", timePreAlloc, " us");

   if(timePreAlloc > 0) {
      double improvement = (double)(timeAlloc - timePreAlloc) / timePreAlloc * 100.0;
      Print("Performance Improvement: ", DoubleToString(improvement, 2), "%");
   }
}
