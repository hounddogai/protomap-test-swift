import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal template calculation.
    protocol GoalTemplateModifier {
        func describe() -> String
        func adjust(_ item: GoalTemplate, value: Double) -> Double
    }

    final class FlaggedGoalTemplateAdjuster: GoalTemplateModifier {
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

        func adjust(_ item: GoalTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGoalTemplateAdjuster: GoalTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GoalTemplateAttemptsOffsetAdjuster: GoalTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: GoalTemplate, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentGoalTemplateAdjuster: GoalTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal template steps in order and keeps a trace of each.
    final class GoalTemplateEngine {
        var steps: [any GoalTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalTemplate) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [GoalTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalTemplateEngine(_ flags: Kit.Flags.Registry) -> GoalTemplateEngine {
        return GoalTemplateEngine(
            steps: [
                FlaggedGoalTemplateAdjuster(flags: flags, flag: "goal-template-default", percent: 0.0),
                RoundingGoalTemplateAdjuster(step: 0.5),
                GoalTemplateAttemptsOffsetAdjuster(weight: 1.01),
                PercentGoalTemplateAdjuster(percent: -18.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 80676.1
        )
    }
}
