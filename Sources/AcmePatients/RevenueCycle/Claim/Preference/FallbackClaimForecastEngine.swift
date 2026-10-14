import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback claim forecast calculation.
    protocol FallbackClaimForecastAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double
    }

    final class RoundingFallbackClaimForecastAdjuster: FallbackClaimForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackClaimForecastAdjuster: FallbackClaimForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackClaimForecastAdjuster: FallbackClaimForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackClaimForecastAdjuster: FallbackClaimForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackClaimForecastExpiresAtOffsetAdjuster: FallbackClaimForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class NameFallbackClaimForecastAdjuster: FallbackClaimForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackClaimForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback claim forecast steps in order and keeps a trace of each.
    final class FallbackClaimForecastEngine {
        var steps: [any FallbackClaimForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackClaimForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackClaimForecast) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackClaimForecastAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FallbackClaimForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackClaimForecastEngine() -> FallbackClaimForecastEngine {
        return FallbackClaimForecastEngine(
            steps: [
                RoundingFallbackClaimForecastAdjuster(step: 1.0),
                CapFallbackClaimForecastAdjuster(cap: 15636.0),
                TieredFallbackClaimForecastAdjuster(
                    bounds: [372.0, 5762.0, 6153.0, 6539.0],
                    rates: [0.89, 1.05, 1.13, 0.8]
                ),
                MinimumFallbackClaimForecastAdjuster(minimum: 24.8),
                FallbackClaimForecastExpiresAtOffsetAdjuster(weight: 1.22),
                NameFallbackClaimForecastAdjuster(factors: ["south": 0.91, "online": 1.17, "east": 1.08]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 70615.9
        )
    }
}
