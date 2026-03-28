//+------------------------------------------------------------------+
//|                                     Benchmark_ZeroAllocation.mq5 |
//|                        Copyright 2025, MetaQuotes Ltd.           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property script_show_inputs

input int Iterations = 1000000;
input int BufferSize = 100;

//+------------------------------------------------------------------+
//| Standard MQL5 Array (Dynamic)                                    |
//+------------------------------------------------------------------+
void BenchmarkStandard()
  {
   ulong start = GetMicrosecondCount();
   double buffer[];

   for(int i=0; i<Iterations; i++)
     {
      ArrayResize(buffer, BufferSize); // Resizing every tick is expensive
      // Shift logic
      for(int j=BufferSize-1; j>0; j--)
         buffer[j] = buffer[j-1];
      buffer[0] = (double)i;
     }

   ulong end = GetMicrosecondCount();
   PrintFormat("Standard MQL5 (Dynamic ArrayResize + Shift): %llu us", end - start);
  }

//+------------------------------------------------------------------+
//| Zenith Zero-Alloc Circular Buffer (Static)                       |
//+------------------------------------------------------------------+
void BenchmarkZenith()
  {
   ulong start = GetMicrosecondCount();
   double buffer[];
   ArrayResize(buffer, BufferSize); // Only once!
   int head = 0;

   for(int i=0; i<Iterations; i++)
     {
      // O(1) update: No resize, no shift loop
      buffer[head] = (double)i;
      head = (head + 1) % BufferSize;
     }

   ulong end = GetMicrosecondCount();
   PrintFormat("Zenith Zero-Alloc (Circular Buffer): %llu us", end - start);
  }

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("Starting Benchmark with ", Iterations, " iterations...");
   BenchmarkStandard();
   BenchmarkZenith();
   Print("Benchmark Complete.");
  }
