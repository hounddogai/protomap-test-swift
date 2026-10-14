import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal schedule calculation.
    protocol GoalScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: GoalSchedule, value: Double) -> Double
    }

    final class CapGoalScheduleAdjuster: GoalScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGoalScheduleAdjuster: GoalScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGoalScheduleAdjuster: GoalScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GoalScheduleCeilingOffsetAdjuster: GoalScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: GoalSchedule, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the goal schedule steps in order and keeps a trace of each.
    final class GoalScheduleEngine {
        var steps: [any GoalScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GoalSchedule) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [GoalSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGoalScheduleEngine() -> GoalScheduleEngine {
        return GoalScheduleEngine(
            steps: [
                CapGoalScheduleAdjuster(cap: 46917.0),
                MinimumGoalScheduleAdjuster(minimum: 32.7),
                PercentGoalScheduleAdjuster(percent: -18.3),
                GoalScheduleCeilingOffsetAdjuster(weight: 1.43),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 22664.2
        )
    }
}
