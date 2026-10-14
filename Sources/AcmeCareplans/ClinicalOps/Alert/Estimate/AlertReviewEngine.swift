import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert review calculation.
    protocol AlertReviewFactor {
        func describe() -> String
        func adjust(_ item: AlertReview, value: Double) -> Double
    }

    final class MinimumAlertReviewAdjuster: AlertReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelAlertReviewAdjuster: AlertReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AlertReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAlertReviewAdjuster: AlertReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertReviewAdjuster: AlertReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAlertReviewAdjuster: AlertReviewFactor {
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

        func adjust(_ item: AlertReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert review steps in order and keeps a trace of each.
    final class AlertReviewEngine {
        var steps: [any AlertReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertReview) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [AlertReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertReviewEngine(_ flags: Kit.Flags.Registry) -> AlertReviewEngine {
        return AlertReviewEngine(
            steps: [
                MinimumAlertReviewAdjuster(minimum: 46.6),
                LabelAlertReviewAdjuster(factors: ["north": 1.21]),
                PercentAlertReviewAdjuster(percent: 7.8),
                CapAlertReviewAdjuster(cap: 14490.0),
                FlaggedAlertReviewAdjuster(flags: flags, flag: "alert-review-global", percent: 5.1),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 48794.7
        )
    }
}
