import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal segment calculation.
    protocol GoalSegmentModifier {
        func describe() -> String
        func adjust(_ item: GoalSegment, value: Double) -> Double
    }

    final class CountryGoalSegmentAdjuster: GoalSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GoalSegmentWindowDaysOffsetAdjuster: GoalSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RoundingGoalSegmentAdjuster: GoalSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGoalSegmentAdjuster: GoalSegmentModifier {
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

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGoalSegmentAdjuster: GoalSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGoalSegmentAdjuster: GoalSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal segment steps in order and keeps a trace of each.
    final class GoalSegmentEngine {
        var steps: [any GoalSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalSegment) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [GoalSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalSegmentEngine(_ flags: Kit.Flags.Registry) -> GoalSegmentEngine {
        return GoalSegmentEngine(
            steps: [
                CountryGoalSegmentAdjuster(factors: ["east": 0.99, "south": 0.91, "retail": 1.33]),
                GoalSegmentWindowDaysOffsetAdjuster(weight: 0.36),
                RoundingGoalSegmentAdjuster(step: 5.0),
                FlaggedGoalSegmentAdjuster(flags: flags, flag: "goal-segment-lenient", percent: -1.7),
                MinimumGoalSegmentAdjuster(minimum: 21.8),
                PercentGoalSegmentAdjuster(percent: -18.8),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 15775.5
        )
    }
}
