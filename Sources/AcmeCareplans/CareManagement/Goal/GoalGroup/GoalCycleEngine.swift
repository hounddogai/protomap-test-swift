import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal cycle calculation.
    protocol GoalCycleStep {
        func describe() -> String
        func adjust(_ item: GoalCycle, value: Double) -> Double
    }

    final class TieredGoalCycleAdjuster: GoalCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGoalCycleAdjuster: GoalCycleStep {
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

        func adjust(_ item: GoalCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGoalCycleAdjuster: GoalCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelGoalCycleAdjuster: GoalCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GoalCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GoalCycleRatioOffsetAdjuster: GoalCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: GoalCycle, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the goal cycle steps in order and keeps a trace of each.
    final class GoalCycleEngine {
        var steps: [any GoalCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalCycle) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalCycleStep = steps[index]
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

        func evaluateAll(_ items: [GoalCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalCycleEngine(_ flags: Kit.Flags.Registry) -> GoalCycleEngine {
        return GoalCycleEngine(
            steps: [
                TieredGoalCycleAdjuster(bounds: [4222.0, 7288.0, 9948.0], rates: [0.81, 1.08, 1.08]),
                FlaggedGoalCycleAdjuster(flags: flags, flag: "goal-cycle-weighted", percent: -8.3),
                CapGoalCycleAdjuster(cap: 28389.0),
                ChannelGoalCycleAdjuster(factors: ["central": 1.22]),
                GoalCycleRatioOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 89330.5
        )
    }
}
