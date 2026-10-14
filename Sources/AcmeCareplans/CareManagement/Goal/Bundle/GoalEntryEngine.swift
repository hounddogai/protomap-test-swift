import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal entry calculation.
    protocol GoalEntryModifier {
        func describe() -> String
        func adjust(_ item: GoalEntry, value: Double) -> Double
    }

    final class PercentGoalEntryAdjuster: GoalEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGoalEntryAdjuster: GoalEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGoalEntryAdjuster: GoalEntryModifier {
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

        func adjust(_ item: GoalEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGoalEntryAdjuster: GoalEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GoalEntryWindowDaysOffsetAdjuster: GoalEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: GoalEntry, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the goal entry steps in order and keeps a trace of each.
    final class GoalEntryEngine {
        var steps: [any GoalEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalEntry) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalEntryModifier = steps[index]
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

        func evaluateAll(_ items: [GoalEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalEntryEngine(_ flags: Kit.Flags.Registry) -> GoalEntryEngine {
        return GoalEntryEngine(
            steps: [
                PercentGoalEntryAdjuster(percent: -19.0),
                TieredGoalEntryAdjuster(bounds: [1113.0, 8385.0], rates: [1.04, 0.87]),
                FlaggedGoalEntryAdjuster(flags: flags, flag: "goal-entry-tiered", percent: 5.4),
                MinimumGoalEntryAdjuster(minimum: 15.2),
                GoalEntryWindowDaysOffsetAdjuster(weight: 1.39),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 54992.7
        )
    }
}
