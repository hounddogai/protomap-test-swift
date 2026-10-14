import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted read preference calculation.
    protocol WeightedReadPreferenceStep {
        func describe() -> String
        func adjust(_ item: WeightedReadPreference, value: Double) -> Double
    }

    final class CapWeightedReadPreferenceAdjuster: WeightedReadPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReadPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedReadPreferenceAdjuster: WeightedReadPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReadPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedReadPreferenceAdjuster: WeightedReadPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedReadPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted read preference steps in order and keeps a trace of each.
    final class WeightedReadPreferenceEngine {
        var steps: [any WeightedReadPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReadPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedReadPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedReadPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [WeightedReadPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedReadPreferenceEngine() -> WeightedReadPreferenceEngine {
        return WeightedReadPreferenceEngine(
            steps: [
                CapWeightedReadPreferenceAdjuster(cap: 5243.0),
                RoundingWeightedReadPreferenceAdjuster(step: 0.1),
                TieredWeightedReadPreferenceAdjuster(
                    bounds: [2908.0, 3731.0, 5294.0, 7952.0],
                    rates: [1.12, 1.14, 0.89, 1.14]
                ),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 33134.2
        )
    }
}
