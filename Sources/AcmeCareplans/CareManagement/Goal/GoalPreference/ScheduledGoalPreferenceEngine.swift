import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled goal preference calculation.
    protocol ScheduledGoalPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledGoalPreference, value: Double) -> Double
    }

    final class MinimumScheduledGoalPreferenceAdjuster: ScheduledGoalPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledGoalPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledGoalPreferenceWeightOffsetAdjuster: ScheduledGoalPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ScheduledGoalPreference, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class RoundingScheduledGoalPreferenceAdjuster: ScheduledGoalPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledGoalPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled goal preference steps in order and keeps a trace of each.
    final class ScheduledGoalPreferenceEngine {
        var steps: [any ScheduledGoalPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledGoalPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledGoalPreference) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledGoalPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledGoalPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledGoalPreferenceEngine() -> ScheduledGoalPreferenceEngine {
        return ScheduledGoalPreferenceEngine(
            steps: [
                MinimumScheduledGoalPreferenceAdjuster(minimum: 3.6),
                ScheduledGoalPreferenceWeightOffsetAdjuster(weight: 1.32),
                RoundingScheduledGoalPreferenceAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 81403.7
        )
    }
}
