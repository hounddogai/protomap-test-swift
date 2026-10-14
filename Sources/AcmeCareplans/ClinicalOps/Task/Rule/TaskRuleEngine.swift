import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task rule calculation.
    protocol TaskRuleStep {
        func describe() -> String
        func adjust(_ item: TaskRule, value: Double) -> Double
    }

    final class TieredTaskRuleAdjuster: TaskRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTaskRuleAdjuster: TaskRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTaskRuleAdjuster: TaskRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTaskRuleAdjuster: TaskRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTaskRuleAdjuster: TaskRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TaskRuleCeilingOffsetAdjuster: TaskRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: TaskRule, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the task rule steps in order and keeps a trace of each.
    final class TaskRuleEngine {
        var steps: [any TaskRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TaskRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskRuleStep = steps[index]
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

        func evaluateAll(_ items: [TaskRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTaskRuleEngine() -> TaskRuleEngine {
        return TaskRuleEngine(
            steps: [
                TieredTaskRuleAdjuster(bounds: [1483.0, 5509.0], rates: [1.13, 1.14]),
                MinimumTaskRuleAdjuster(minimum: 16.5),
                PercentTaskRuleAdjuster(percent: 13.8),
                RoundingTaskRuleAdjuster(step: 0.5),
                CapTaskRuleAdjuster(cap: 38261.0),
                TaskRuleCeilingOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 63414.5
        )
    }
}
