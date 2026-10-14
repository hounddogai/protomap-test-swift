import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled task review calculation.
    protocol ScheduledTaskReviewStep {
        func describe() -> String
        func adjust(_ item: ScheduledTaskReview, value: Double) -> Double
    }

    final class CapScheduledTaskReviewAdjuster: ScheduledTaskReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledTaskReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledTaskReviewAdjuster: ScheduledTaskReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledTaskReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledTaskReviewAdjuster: ScheduledTaskReviewStep {
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

        func adjust(_ item: ScheduledTaskReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledTaskReviewAdjuster: ScheduledTaskReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledTaskReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled task review steps in order and keeps a trace of each.
    final class ScheduledTaskReviewEngine {
        var steps: [any ScheduledTaskReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledTaskReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledTaskReview) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ScheduledTaskReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledTaskReviewEngine(_ flags: Kit.Flags.Registry) -> ScheduledTaskReviewEngine {
        return ScheduledTaskReviewEngine(
            steps: [
                CapScheduledTaskReviewAdjuster(cap: 27920.0),
                MinimumScheduledTaskReviewAdjuster(minimum: 9.0),
                FlaggedScheduledTaskReviewAdjuster(flags: flags, flag: "scheduled-task-review-manual", percent: 0.4),
                PercentScheduledTaskReviewAdjuster(percent: -6.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 4667.9
        )
    }
}
