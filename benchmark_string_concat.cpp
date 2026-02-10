#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <cstdio>
#include <cstring>

// Simulate MQL5 functions
std::string _Symbol = "EURUSD";
int _Digits = 5;
double SymbolInfoDouble(const std::string& symbol, int prop_id) {
    return 1.12345;
}
std::string DoubleToString(double value, int digits) {
    char buffer[32];
    sprintf(buffer, "%.*f", digits, value);
    return std::string(buffer);
}
const int SYMBOL_BID = 1;

void benchmark_inefficient() {
    std::string dashboard;
    dashboard = "╔════════════════════════════════════════════════╗\n";
    dashboard += "║               TRADING DASHBOARD                ║\n";
    dashboard += "╠════════════════════════════════════════════════╣\n";
    dashboard += "║ Symbol: " + _Symbol + "                          ║\n";
    dashboard += "║ Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "               ║\n";
    dashboard += "╚════════════════════════════════════════════════╝\n";

    // Prevent optimization
    if (dashboard.length() == 0) printf("Error\n");
}

void benchmark_efficient() {
    char buffer[1024];
    // Simulating StringFormat
    // In MQL5 StringFormat, %s handles strings directly, and formatting double is %f
    // Here we use snprintf to mimic the single-pass formatting
    snprintf(buffer, sizeof(buffer),
        "╔════════════════════════════════════════════════╗\n"
        "║               TRADING DASHBOARD                ║\n"
        "╠════════════════════════════════════════════════╣\n"
        "║ Symbol: %-32s ║\n"
        "║ Price: %-33.5f ║\n"
        "╚════════════════════════════════════════════════╝\n",
        _Symbol.c_str(), SymbolInfoDouble(_Symbol, SYMBOL_BID));

    // Prevent optimization
    if (strlen(buffer) == 0) printf("Error\n");
}

int main() {
    const int iterations = 1000000;

    std::cout << "Running benchmark with " << iterations << " iterations..." << std::endl;

    auto start = std::chrono::high_resolution_clock::now();
    for(int i=0; i<iterations; ++i) {
        benchmark_inefficient();
    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff_inefficient = end - start;
    std::cout << "Inefficient (+=): " << diff_inefficient.count() << " s\n";

    start = std::chrono::high_resolution_clock::now();
    for(int i=0; i<iterations; ++i) {
        benchmark_efficient();
    }
    end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff_efficient = end - start;
    std::cout << "Efficient (snprintf): " << diff_efficient.count() << " s\n";

    if (diff_efficient.count() > 0)
        std::cout << "Speedup: " << diff_inefficient.count() / diff_efficient.count() << "x\n";
    else
        std::cout << "Speedup: Infinite (efficient took 0s)\n";

    return 0;
}
