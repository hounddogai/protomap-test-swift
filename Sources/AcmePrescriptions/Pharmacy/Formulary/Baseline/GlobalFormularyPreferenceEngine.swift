import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global formulary preference calculation.
    protocol GlobalFormularyPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double
    }

    final class CapGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalFormularyPreferenceAdjuster: GlobalFormularyPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalFormularyPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global formulary preference steps in order and keeps a trace of each.
    final class GlobalFormularyPreferenceEngine {
        var steps: [any GlobalFormularyPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalFormularyPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalFormularyPreference) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalFormularyPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalFormularyPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalFormularyPreferenceEngine() -> GlobalFormularyPreferenceEngine {
        return GlobalFormularyPreferenceEngine(
            steps: [
                CapGlobalFormularyPreferenceAdjuster(cap: 30904.0),
                MinimumGlobalFormularyPreferenceAdjuster(minimum: 42.8),
                RoundingGlobalFormularyPreferenceAdjuster(step: 0.5),
                PercentGlobalFormularyPreferenceAdjuster(percent: -14.0),
                CategoryGlobalFormularyPreferenceAdjuster(factors: ["south": 0.78, "west": 1.27]),
                TieredGlobalFormularyPreferenceAdjuster(bounds: [794.0, 5315.0], rates: [1.16, 0.93]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 66383.3
        )
    }
}
