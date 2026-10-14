import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task review calculation.
    protocol TaskReviewFactor {
        func describe() -> String
        func adjust(_ item: TaskReview, value: Double) -> Double
    }

    final class CapTaskReviewAdjuster: TaskReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryTaskReviewAdjuster: TaskReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TaskReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTaskReviewAdjuster: TaskReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTaskReviewAdjuster: TaskReviewFactor {
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

        func adjust(_ item: TaskReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task review steps in order and keeps a trace of each.
    final class TaskReviewEngine {
        var steps: [any TaskReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskReview) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskReviewFactor = steps[index]
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

        func evaluateAll(_ items: [TaskReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskReviewEngine(_ flags: Kit.Flags.Registry) -> TaskReviewEngine {
        return TaskReviewEngine(
            steps: [
                CapTaskReviewAdjuster(cap: 9288.0),
                CategoryTaskReviewAdjuster(factors: ["north": 0.8]),
                MinimumTaskReviewAdjuster(minimum: 12.2),
                FlaggedTaskReviewAdjuster(flags: flags, flag: "task-review-default", percent: 5.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 67747.4
        )
    }
}
