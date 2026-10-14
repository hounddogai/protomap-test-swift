import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive rounding preference calculation.
    protocol AdaptiveRoundingPreferenceFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveRoundingPreference, value: Double) -> Double
    }

    final class RoundingAdaptiveRoundingPreferenceAdjuster: AdaptiveRoundingPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRoundingPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveRoundingPreferenceAdjuster: AdaptiveRoundingPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRoundingPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveRoundingPreferenceAdjuster: AdaptiveRoundingPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRoundingPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive rounding preference steps in order and keeps a trace of each.
    final class AdaptiveRoundingPreferenceEngine {
        var steps: [any AdaptiveRoundingPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRoundingPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveRoundingPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRoundingPreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRoundingPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRoundingPreferenceEngine() -> AdaptiveRoundingPreferenceEngine {
        return AdaptiveRoundingPreferenceEngine(
            steps: [
                RoundingAdaptiveRoundingPreferenceAdjuster(step: 0.1),
                TieredAdaptiveRoundingPreferenceAdjuster(bounds: [5888.0, 8199.0], rates: [0.99, 0.95]),
                MinimumAdaptiveRoundingPreferenceAdjuster(minimum: 47.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 60944.0
        )
    }
}
