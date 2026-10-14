import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global closure rule calculation.
    protocol GlobalClosureRuleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalClosureRule, value: Double) -> Double
    }

    final class NameGlobalClosureRuleAdjuster: GlobalClosureRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalClosureRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalClosureRuleAdjuster: GlobalClosureRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalClosureRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalClosureRulePriorityOffsetAdjuster: GlobalClosureRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: GlobalClosureRule, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumGlobalClosureRuleAdjuster: GlobalClosureRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalClosureRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalClosureRuleAdjuster: GlobalClosureRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalClosureRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global closure rule steps in order and keeps a trace of each.
    final class GlobalClosureRuleEngine {
        var steps: [any GlobalClosureRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalClosureRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalClosureRule) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalClosureRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalClosureRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalClosureRuleEngine() -> GlobalClosureRuleEngine {
        return GlobalClosureRuleEngine(
            steps: [
                NameGlobalClosureRuleAdjuster(factors: ["east": 1.27]),
                CapGlobalClosureRuleAdjuster(cap: 5266.0),
                GlobalClosureRulePriorityOffsetAdjuster(weight: 0.87),
                MinimumGlobalClosureRuleAdjuster(minimum: 31.3),
                TieredGlobalClosureRuleAdjuster(bounds: [5108.0, 5482.0], rates: [1.11, 1.2]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 24001.0
        )
    }
}
