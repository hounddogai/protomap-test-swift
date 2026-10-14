import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted result rule calculation.
    protocol WeightedResultRuleFactor {
        func describe() -> String
        func adjust(_ item: WeightedResultRule, value: Double) -> Double
    }

    final class PercentWeightedResultRuleAdjuster: WeightedResultRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedResultRuleAdjuster: WeightedResultRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedResultRuleAdjuster: WeightedResultRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedResultRuleStartsAtOffsetAdjuster: WeightedResultRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingWeightedResultRuleAdjuster: WeightedResultRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameWeightedResultRuleAdjuster: WeightedResultRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedResultRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted result rule steps in order and keeps a trace of each.
    final class WeightedResultRuleEngine {
        var steps: [any WeightedResultRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedResultRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedResultRule) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedResultRuleFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedResultRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedResultRuleEngine() -> WeightedResultRuleEngine {
        return WeightedResultRuleEngine(
            steps: [
                PercentWeightedResultRuleAdjuster(percent: -15.0),
                MinimumWeightedResultRuleAdjuster(minimum: 34.9),
                CapWeightedResultRuleAdjuster(cap: 41363.0),
                WeightedResultRuleStartsAtOffsetAdjuster(weight: 0.42),
                RoundingWeightedResultRuleAdjuster(step: 0.5),
                NameWeightedResultRuleAdjuster(factors: ["north": 1.1]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 56866.1
        )
    }
}
