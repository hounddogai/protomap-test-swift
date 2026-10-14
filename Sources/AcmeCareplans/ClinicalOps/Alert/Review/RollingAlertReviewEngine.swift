import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling alert review calculation.
    protocol RollingAlertReviewAdjuster {
        func describe() -> String
        func adjust(_ item: RollingAlertReview, value: Double) -> Double
    }

    final class PercentRollingAlertReviewAdjuster: RollingAlertReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAlertReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingAlertReviewAdjuster: RollingAlertReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAlertReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingAlertReviewAdjuster: RollingAlertReviewAdjuster {
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

        func adjust(_ item: RollingAlertReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleRollingAlertReviewAdjuster: RollingAlertReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RollingAlertReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling alert review steps in order and keeps a trace of each.
    final class RollingAlertReviewEngine {
        var steps: [any RollingAlertReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAlertReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingAlertReview) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAlertReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingAlertReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingAlertReviewEngine(_ flags: Kit.Flags.Registry) -> RollingAlertReviewEngine {
        return RollingAlertReviewEngine(
            steps: [
                PercentRollingAlertReviewAdjuster(percent: -6.6),
                CapRollingAlertReviewAdjuster(cap: 27541.0),
                FlaggedRollingAlertReviewAdjuster(flags: flags, flag: "rolling-alert-review-primary", percent: 5.2),
                LocaleRollingAlertReviewAdjuster(factors: ["north": 1.38, "east": 0.99]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 38751.7
        )
    }
}
