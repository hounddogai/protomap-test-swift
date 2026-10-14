import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted accession rule calculation.
    protocol WeightedAccessionRuleAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedAccessionRule, value: Double) -> Double
    }

    final class TieredWeightedAccessionRuleAdjuster: WeightedAccessionRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAccessionRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedAccessionRuleAdjuster: WeightedAccessionRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedAccessionRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedAccessionRuleAdjuster: WeightedAccessionRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedAccessionRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedAccessionRuleRatioOffsetAdjuster: WeightedAccessionRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedAccessionRule, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the weighted accession rule steps in order and keeps a trace of each.
    final class WeightedAccessionRuleEngine {
        var steps: [any WeightedAccessionRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAccessionRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedAccessionRule) -> Double {
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

        func evaluateAll(_ items: [WeightedAccessionRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedAccessionRuleEngine() -> WeightedAccessionRuleEngine {
        return WeightedAccessionRuleEngine(
            steps: [
                TieredWeightedAccessionRuleAdjuster(
                    bounds: [48.0, 2023.0, 2391.0, 8096.0],
                    rates: [0.8, 1.01, 1.05, 1.08]
                ),
                CapWeightedAccessionRuleAdjuster(cap: 14060.0),
                RoundingWeightedAccessionRuleAdjuster(step: 0.1),
                WeightedAccessionRuleRatioOffsetAdjuster(weight: 1.44),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 18213.9
        )
    }
}
