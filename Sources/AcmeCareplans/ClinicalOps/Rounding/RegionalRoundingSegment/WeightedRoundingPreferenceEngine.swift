import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted rounding preference calculation.
    protocol WeightedRoundingPreferenceFactor {
        func describe() -> String
        func adjust(_ item: WeightedRoundingPreference, value: Double) -> Double
    }

    final class RegionWeightedRoundingPreferenceAdjuster: WeightedRoundingPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedRoundingPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedRoundingPreferenceAdjuster: WeightedRoundingPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRoundingPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedRoundingPreferenceAdjuster: WeightedRoundingPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedRoundingPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedRoundingPreferenceAdjuster: WeightedRoundingPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRoundingPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted rounding preference steps in order and keeps a trace of each.
    final class WeightedRoundingPreferenceEngine {
        var steps: [any WeightedRoundingPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRoundingPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedRoundingPreference) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [WeightedRoundingPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedRoundingPreferenceEngine() -> WeightedRoundingPreferenceEngine {
        return WeightedRoundingPreferenceEngine(
            steps: [
                RegionWeightedRoundingPreferenceAdjuster(factors: ["online": 0.72]),
                TieredWeightedRoundingPreferenceAdjuster(bounds: [2250.0, 4399.0], rates: [0.98, 0.9]),
                RoundingWeightedRoundingPreferenceAdjuster(step: 1.0),
                MinimumWeightedRoundingPreferenceAdjuster(minimum: 9.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 50915.8
        )
    }
}
