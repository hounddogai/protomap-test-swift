import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending goal schedule calculation.
    protocol PendingGoalScheduleFactor {
        func describe() -> String
        func adjust(_ item: PendingGoalSchedule, value: Double) -> Double
    }

    final class NamePendingGoalScheduleAdjuster: PendingGoalScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingGoalSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingGoalScheduleAdjuster: PendingGoalScheduleFactor {
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

        func adjust(_ item: PendingGoalSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingGoalScheduleAdjuster: PendingGoalScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingGoalSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending goal schedule steps in order and keeps a trace of each.
    final class PendingGoalScheduleEngine {
        var steps: [any PendingGoalScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingGoalScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingGoalSchedule) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingGoalScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [PendingGoalSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingGoalScheduleEngine(_ flags: Kit.Flags.Registry) -> PendingGoalScheduleEngine {
        return PendingGoalScheduleEngine(
            steps: [
                NamePendingGoalScheduleAdjuster(factors: ["west": 1.01]),
                FlaggedPendingGoalScheduleAdjuster(
                    flags: flags,
                    flag: "pending-goal-schedule-adaptive",
                    percent: -4.3
                ),
                RoundingPendingGoalScheduleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 26001.2
        )
    }
}
