import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled courier review calculation.
    protocol ScheduledCourierReviewModifier {
        func describe() -> String
        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double
    }

    final class ScheduledCourierReviewCeilingOffsetAdjuster: ScheduledCourierReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class NameScheduledCourierReviewAdjuster: ScheduledCourierReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledCourierReviewAdjuster: ScheduledCourierReviewModifier {
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

        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledCourierReviewAdjuster: ScheduledCourierReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledCourierReviewAdjuster: ScheduledCourierReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCourierReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled courier review steps in order and keeps a trace of each.
    final class ScheduledCourierReviewEngine {
        var steps: [any ScheduledCourierReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCourierReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCourierReview) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ScheduledCourierReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCourierReviewEngine(_ flags: Kit.Flags.Registry) -> ScheduledCourierReviewEngine {
        return ScheduledCourierReviewEngine(
            steps: [
                ScheduledCourierReviewCeilingOffsetAdjuster(weight: 1.35),
                NameScheduledCourierReviewAdjuster(factors: ["retail": 1.39]),
                FlaggedScheduledCourierReviewAdjuster(
                    flags: flags,
                    flag: "scheduled-courier-review-strict",
                    percent: -9.9
                ),
                PercentScheduledCourierReviewAdjuster(percent: 16.5),
                RoundingScheduledCourierReviewAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 82946.4
        )
    }
}
