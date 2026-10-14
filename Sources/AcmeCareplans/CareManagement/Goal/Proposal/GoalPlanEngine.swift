import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal plan calculation.
    protocol GoalPlanAdjuster {
        func describe() -> String
        func adjust(_ item: GoalPlan, value: Double) -> Double
    }

    final class CapGoalPlanAdjuster: GoalPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGoalPlanAdjuster: GoalPlanAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: GoalPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameGoalPlanAdjuster: GoalPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GoalPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGoalPlanAdjuster: GoalPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the goal plan steps in order and keeps a trace of each.
    final class GoalPlanEngine {
        var steps: [any GoalPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GoalPlan) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [GoalPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGoalPlanEngine(_ flags: Kit.Flags.Registry) -> GoalPlanEngine {
        return GoalPlanEngine(
            steps: [
                CapGoalPlanAdjuster(cap: 33305.0),
                FlaggedGoalPlanAdjuster(flags: flags, flag: "goal-plan-pending", percent: 1.9),
                NameGoalPlanAdjuster(factors: ["central": 1.04, "retail": 0.7]),
                TieredGoalPlanAdjuster(bounds: [3984.0, 4742.0], rates: [1.03, 0.98]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 96229.2
        )
    }
}
