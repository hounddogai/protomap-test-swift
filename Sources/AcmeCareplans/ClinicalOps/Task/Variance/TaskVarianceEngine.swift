import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task variance calculation.
    protocol TaskVarianceStep {
        func describe() -> String
        func adjust(_ item: TaskVariance, value: Double) -> Double
    }

    final class RoundingTaskVarianceAdjuster: TaskVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTaskVarianceAdjuster: TaskVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTaskVarianceAdjuster: TaskVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTaskVarianceAdjuster: TaskVarianceStep {
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

        func adjust(_ item: TaskVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task variance steps in order and keeps a trace of each.
    final class TaskVarianceEngine {
        var steps: [any TaskVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskVariance) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [TaskVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskVarianceEngine(_ flags: Kit.Flags.Registry) -> TaskVarianceEngine {
        return TaskVarianceEngine(
            steps: [
                RoundingTaskVarianceAdjuster(step: 0.5),
                CapTaskVarianceAdjuster(cap: 38072.0),
                MinimumTaskVarianceAdjuster(minimum: 39.8),
                FlaggedTaskVarianceAdjuster(flags: flags, flag: "task-variance-capped", percent: 1.3),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 65705.0
        )
    }
}
