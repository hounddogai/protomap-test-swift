import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier review calculation.
    protocol DefaultCourierReviewAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCourierReview, value: Double) -> Double
    }

    final class PercentDefaultCourierReviewAdjuster: DefaultCourierReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCourierReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultCourierReviewAdjuster: DefaultCourierReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCourierReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultCourierReviewAdjuster: DefaultCourierReviewAdjuster {
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

        func adjust(_ item: DefaultCourierReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultCourierReviewQuantityOffsetAdjuster: DefaultCourierReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DefaultCourierReview, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the default courier review steps in order and keeps a trace of each.
    final class DefaultCourierReviewEngine {
        var steps: [any DefaultCourierReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCourierReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierReviewEngine(_ flags: Kit.Flags.Registry) -> DefaultCourierReviewEngine {
        return DefaultCourierReviewEngine(
            steps: [
                PercentDefaultCourierReviewAdjuster(percent: -18.5),
                CapDefaultCourierReviewAdjuster(cap: 26943.0),
                FlaggedDefaultCourierReviewAdjuster(
                    flags: flags,
                    flag: "default-courier-review-default",
                    percent: 7.0
                ),
                DefaultCourierReviewQuantityOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 78465.4
        )
    }
}
