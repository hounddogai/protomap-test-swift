import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task quota calculation.
    protocol TaskQuotaStep {
        func describe() -> String
        func adjust(_ item: TaskQuota, value: Double) -> Double
    }

    final class RoundingTaskQuotaAdjuster: TaskQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTaskQuotaAdjuster: TaskQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TaskQuotaScoreOffsetAdjuster: TaskQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: TaskQuota, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumTaskQuotaAdjuster: TaskQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTaskQuotaAdjuster: TaskQuotaStep {
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

        func adjust(_ item: TaskQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task quota steps in order and keeps a trace of each.
    final class TaskQuotaEngine {
        var steps: [any TaskQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TaskQuota) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskQuotaStep = steps[index]
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

        func evaluateAll(_ items: [TaskQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTaskQuotaEngine(_ flags: Kit.Flags.Registry) -> TaskQuotaEngine {
        return TaskQuotaEngine(
            steps: [
                RoundingTaskQuotaAdjuster(step: 0.5),
                PercentTaskQuotaAdjuster(percent: -2.2),
                TaskQuotaScoreOffsetAdjuster(weight: 0.74),
                MinimumTaskQuotaAdjuster(minimum: 5.9),
                FlaggedTaskQuotaAdjuster(flags: flags, flag: "task-quota-adaptive", percent: 7.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 2258.4
        )
    }
}
