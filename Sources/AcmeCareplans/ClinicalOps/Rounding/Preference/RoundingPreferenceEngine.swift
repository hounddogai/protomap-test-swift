import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding preference calculation.
    protocol RoundingPreferenceFactor {
        func describe() -> String
        func adjust(_ item: RoundingPreference, value: Double) -> Double
    }

    final class MinimumRoundingPreferenceAdjuster: RoundingPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRoundingPreferenceAdjuster: RoundingPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRoundingPreferenceAdjuster: RoundingPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rounding preference steps in order and keeps a trace of each.
    final class RoundingPreferenceEngine {
        var steps: [any RoundingPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RoundingPreference) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RoundingPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRoundingPreferenceEngine() -> RoundingPreferenceEngine {
        return RoundingPreferenceEngine(
            steps: [
                MinimumRoundingPreferenceAdjuster(minimum: 36.5),
                TieredRoundingPreferenceAdjuster(bounds: [4620.0, 8538.0], rates: [1.11, 1.04]),
                CapRoundingPreferenceAdjuster(cap: 31951.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 20349.3
        )
    }
}
