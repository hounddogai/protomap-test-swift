import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task metric calculation.
    protocol TaskMetricStep {
        func describe() -> String
        func adjust(_ item: TaskMetric, value: Double) -> Double
    }

    final class MinimumTaskMetricAdjuster: TaskMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTaskMetricAdjuster: TaskMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTaskMetricAdjuster: TaskMetricStep {
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

        func adjust(_ item: TaskMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleTaskMetricAdjuster: TaskMetricStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: TaskMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTaskMetricAdjuster: TaskMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the task metric steps in order and keeps a trace of each.
    final class TaskMetricEngine {
        var steps: [any TaskMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskMetric) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [TaskMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskMetricEngine(_ flags: Kit.Flags.Registry) -> TaskMetricEngine {
        return TaskMetricEngine(
            steps: [
                MinimumTaskMetricAdjuster(minimum: 43.7),
                PercentTaskMetricAdjuster(percent: 5.7),
                FlaggedTaskMetricAdjuster(flags: flags, flag: "task-metric-batched", percent: -8.4),
                LocaleTaskMetricAdjuster(factors: ["central": 1.26, "retail": 0.78, "north": 0.89]),
                CapTaskMetricAdjuster(cap: 17950.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 11674.1
        )
    }
}
