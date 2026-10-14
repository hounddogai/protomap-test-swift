import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task summary calculation.
    protocol TaskSummaryModifier {
        func describe() -> String
        func adjust(_ item: TaskSummary, value: Double) -> Double
    }

    final class MinimumTaskSummaryAdjuster: TaskSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameTaskSummaryAdjuster: TaskSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TaskSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTaskSummaryAdjuster: TaskSummaryModifier {
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

        func adjust(_ item: TaskSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task summary steps in order and keeps a trace of each.
    final class TaskSummaryEngine {
        var steps: [any TaskSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskSummary) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [TaskSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskSummaryEngine(_ flags: Kit.Flags.Registry) -> TaskSummaryEngine {
        return TaskSummaryEngine(
            steps: [
                MinimumTaskSummaryAdjuster(minimum: 18.0),
                NameTaskSummaryAdjuster(factors: ["north": 0.85, "west": 1.18]),
                FlaggedTaskSummaryAdjuster(flags: flags, flag: "task-summary-regional", percent: 7.2),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 25964.5
        )
    }
}
