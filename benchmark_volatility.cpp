#include <iostream>
#include <vector>
#include <chrono>
#include <cstring>

// Simulate MqlRates struct
struct MqlRates {
    long long time;
    double open;
    double high;
    double low;
    double close;
    long long tick_volume;
    int spread;
    long long real_volume;
};

// Simulate CopyRates function overhead (just filling data)
int CopyRates(const std::string& symbol, int period, int start, int count, std::vector<MqlRates>& rates) {
    // In MQL5, if rates is dynamic, it might be resized.
    // Simulating resize overhead if vector is empty or wrong size.
    if (rates.size() != (size_t)count) {
        rates.resize(count);
    }
    // Simulate data fill
    for (int i = 0; i < count; ++i) {
        rates[i].high = 1.0005;
        rates[i].low = 1.0001;
    }
    return count;
}

class CZenithProtocol_Unoptimized {
public:
    double CalculateVolatility() {
        std::vector<MqlRates> rates; // Local dynamic array
        if (CopyRates("EURUSD", 0, 0, 1, rates) > 0) {
            return rates[0].high - rates[0].low;
        }
        return 0.0;
    }
};

class CZenithProtocol_Optimized {
    std::vector<MqlRates> m_rates; // Member variable
public:
    CZenithProtocol_Optimized() {
        m_rates.reserve(1); // Pre-allocate capacity
    }

    double CalculateVolatility() {
        // Reuse member vector
        if (CopyRates("EURUSD", 0, 0, 1, m_rates) > 0) {
            return m_rates[0].high - m_rates[0].low;
        }
        return 0.0;
    }
};

int main() {
    const int iterations = 10000000;

    // Benchmark Unoptimized
    {
        CZenithProtocol_Unoptimized unopt;
        auto start = std::chrono::high_resolution_clock::now();
        double sum = 0;
        for (int i = 0; i < iterations; ++i) {
            sum += unopt.CalculateVolatility();
        }
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> diff = end - start;
        std::cout << "Unoptimized Time: " << diff.count() << " s (" << sum << ")" << std::endl;
    }

    // Benchmark Optimized
    {
        CZenithProtocol_Optimized opt;
        auto start = std::chrono::high_resolution_clock::now();
        double sum = 0;
        for (int i = 0; i < iterations; ++i) {
            sum += opt.CalculateVolatility();
        }
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> diff = end - start;
        std::cout << "Optimized Time:   " << diff.count() << " s (" << sum << ")" << std::endl;
    }

    return 0;
}
