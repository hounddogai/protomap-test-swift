import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task adjustment calculation.
    protocol TaskAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: TaskAdjustment, value: Double) -> Double
    }

    final class TaskAdjustmentGraceDaysOffsetAdjuster: TaskAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: TaskAdjustment, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class FlaggedTaskAdjustmentAdjuster: TaskAdjustmentAdjuster {
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

        func adjust(_ item: TaskAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTaskAdjustmentAdjuster: TaskAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTaskAdjustmentAdjuster: TaskAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task adjustment steps in order and keeps a trace of each.
    final class TaskAdjustmentEngine {
        var steps: [any TaskAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskAdjustment) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [TaskAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskAdjustmentEngine(_ flags: Kit.Flags.Registry) -> TaskAdjustmentEngine {
        return TaskAdjustmentEngine(
            steps: [
                TaskAdjustmentGraceDaysOffsetAdjuster(weight: 1.11),
                FlaggedTaskAdjustmentAdjuster(flags: flags, flag: "task-adjustment-fallback", percent: -6.6),
                CapTaskAdjustmentAdjuster(cap: 10660.0),
                PercentTaskAdjustmentAdjuster(percent: -14.1),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 42923.7
        )
    }
}
