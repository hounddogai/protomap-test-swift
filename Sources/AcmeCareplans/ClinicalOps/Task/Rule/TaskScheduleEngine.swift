import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task schedule calculation.
    protocol TaskScheduleFactor {
        func describe() -> String
        func adjust(_ item: TaskSchedule, value: Double) -> Double
    }

    final class CapTaskScheduleAdjuster: TaskScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TaskScheduleMinimumOffsetAdjuster: TaskScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: TaskSchedule, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedTaskScheduleAdjuster: TaskScheduleFactor {
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

        func adjust(_ item: TaskSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTaskScheduleAdjuster: TaskScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the task schedule steps in order and keeps a trace of each.
    final class TaskScheduleEngine {
        var steps: [any TaskScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TaskSchedule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [TaskSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTaskScheduleEngine(_ flags: Kit.Flags.Registry) -> TaskScheduleEngine {
        return TaskScheduleEngine(
            steps: [
                CapTaskScheduleAdjuster(cap: 46304.0),
                TaskScheduleMinimumOffsetAdjuster(weight: 1.13),
                FlaggedTaskScheduleAdjuster(flags: flags, flag: "task-schedule-fallback", percent: -0.5),
                RoundingTaskScheduleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 18609.4
        )
    }
}
