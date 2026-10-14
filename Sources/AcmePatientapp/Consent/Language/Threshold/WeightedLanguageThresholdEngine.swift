import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted language threshold calculation.
    protocol WeightedLanguageThresholdStep {
        func describe() -> String
        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double
    }

    final class RoundingWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedLanguageThresholdAdjuster: WeightedLanguageThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedLanguageThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted language threshold steps in order and keeps a trace of each.
    final class WeightedLanguageThresholdEngine {
        var steps: [any WeightedLanguageThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedLanguageThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedLanguageThreshold) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedLanguageThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedLanguageThresholdEngine() -> WeightedLanguageThresholdEngine {
        return WeightedLanguageThresholdEngine(
            steps: [
                RoundingWeightedLanguageThresholdAdjuster(step: 1.0),
                TieredWeightedLanguageThresholdAdjuster(
                    bounds: [89.0, 1810.0, 7927.0, 9144.0],
                    rates: [1.16, 1.15, 0.95, 0.94]
                ),
                PercentWeightedLanguageThresholdAdjuster(percent: 19.6),
                MinimumWeightedLanguageThresholdAdjuster(minimum: 43.2),
                CategoryWeightedLanguageThresholdAdjuster(factors: ["online": 1.12]),
                CapWeightedLanguageThresholdAdjuster(cap: 25890.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 47149.7
        )
    }
}
