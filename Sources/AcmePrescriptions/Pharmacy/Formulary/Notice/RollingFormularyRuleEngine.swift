import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling formulary rule calculation.
    protocol RollingFormularyRuleFactor {
        func describe() -> String
        func adjust(_ item: RollingFormularyRule, value: Double) -> Double
    }

    final class RollingFormularyRuleDosageMgOffsetAdjuster: RollingFormularyRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: RollingFormularyRule, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumRollingFormularyRuleAdjuster: RollingFormularyRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingFormularyRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameRollingFormularyRuleAdjuster: RollingFormularyRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingFormularyRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingFormularyRuleAdjuster: RollingFormularyRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFormularyRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling formulary rule steps in order and keeps a trace of each.
    final class RollingFormularyRuleEngine {
        var steps: [any RollingFormularyRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFormularyRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingFormularyRule) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [RollingFormularyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingFormularyRuleEngine() -> RollingFormularyRuleEngine {
        return RollingFormularyRuleEngine(
            steps: [
                RollingFormularyRuleDosageMgOffsetAdjuster(weight: 0.82),
                MinimumRollingFormularyRuleAdjuster(minimum: 23.7),
                NameRollingFormularyRuleAdjuster(factors: ["east": 1.37, "north": 0.97, "south": 0.97]),
                TieredRollingFormularyRuleAdjuster(
                    bounds: [118.0, 1215.0, 7372.0, 7607.0],
                    rates: [1.18, 0.98, 0.93, 1.02]
                ),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 53931.0
        )
    }
}
