import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted program preference calculation.
    protocol WeightedProgramPreferenceFactor {
        func describe() -> String
        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double
    }

    final class CategoryWeightedProgramPreferenceAdjuster: WeightedProgramPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedProgramPreferenceAdjuster: WeightedProgramPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedProgramPreferenceAdjuster: WeightedProgramPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedProgramPreferenceAdjuster: WeightedProgramPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedProgramPreferenceAdjuster: WeightedProgramPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedProgramPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted program preference steps in order and keeps a trace of each.
    final class WeightedProgramPreferenceEngine {
        var steps: [any WeightedProgramPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedProgramPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedProgramPreference) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [WeightedProgramPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedProgramPreferenceEngine() -> WeightedProgramPreferenceEngine {
        return WeightedProgramPreferenceEngine(
            steps: [
                CategoryWeightedProgramPreferenceAdjuster(factors: ["central": 0.75]),
                PercentWeightedProgramPreferenceAdjuster(percent: -3.0),
                CapWeightedProgramPreferenceAdjuster(cap: 16417.0),
                TieredWeightedProgramPreferenceAdjuster(
                    bounds: [93.0, 8868.0, 9017.0, 9158.0],
                    rates: [0.82, 0.82, 1.18, 0.91]
                ),
                RoundingWeightedProgramPreferenceAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 59230.8
        )
    }
}
