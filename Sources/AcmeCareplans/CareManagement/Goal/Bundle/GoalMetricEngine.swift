import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal metric calculation.
    protocol GoalMetricStep {
        func describe() -> String
        func adjust(_ item: GoalMetric, value: Double) -> Double
    }

    final class GoalMetricEndsAtOffsetAdjuster: GoalMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapGoalMetricAdjuster: GoalMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardGoalMetricAdjuster: GoalMetricStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGoalMetricAdjuster: GoalMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGoalMetricAdjuster: GoalMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGoalMetricAdjuster: GoalMetricStep {
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

        func adjust(_ item: GoalMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal metric steps in order and keeps a trace of each.
    final class GoalMetricEngine {
        var steps: [any GoalMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GoalMetric) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [GoalMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGoalMetricEngine(_ flags: Kit.Flags.Registry) -> GoalMetricEngine {
        return GoalMetricEngine(
            steps: [
                GoalMetricEndsAtOffsetAdjuster(weight: 0.89),
                CapGoalMetricAdjuster(cap: 33522.0),
                WardGoalMetricAdjuster(factors: ["north": 1.15]),
                PercentGoalMetricAdjuster(percent: -7.9),
                MinimumGoalMetricAdjuster(minimum: 36.8),
                FlaggedGoalMetricAdjuster(flags: flags, flag: "goal-metric-legacy", percent: 5.9),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 59609.0
        )
    }
}
