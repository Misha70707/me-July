#include <vector>
#include <iostream>
#include <chrono>

const int ITERATIONS = 10000000;

void benchmark_allocation() {
    auto start = std::chrono::high_resolution_clock::now();
    double sum = 0;
    for (int i = 0; i < ITERATIONS; ++i) {
        std::vector<double> rsi(1); // Allocation here
        rsi[0] = 0.5;
        sum += rsi[0];
    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;
    std::cout << "Allocation inside loop: " << diff.count() << " s\n";
}

void benchmark_reuse() {
    auto start = std::chrono::high_resolution_clock::now();
    double sum = 0;
    std::vector<double> rsi(1); // Pre-allocation
    for (int i = 0; i < ITERATIONS; ++i) {
        rsi[0] = 0.5; // Reuse
        sum += rsi[0];
    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;
    std::cout << "Reuse buffer: " << diff.count() << " s\n";
}

int main() {
    benchmark_allocation();
    benchmark_reuse();
    return 0;
}
