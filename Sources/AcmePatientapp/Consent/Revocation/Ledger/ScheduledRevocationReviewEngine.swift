import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled revocation review calculation.
    protocol ScheduledRevocationReviewStep {
        func describe() -> String
        func adjust(_ item: ScheduledRevocationReview, value: Double) -> Double
    }

    final class FlaggedScheduledRevocationReviewAdjuster: ScheduledRevocationReviewStep {
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

        func adjust(_ item: ScheduledRevocationReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledRevocationReviewAdjuster: ScheduledRevocationReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRevocationReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledRevocationReviewCeilingOffsetAdjuster: ScheduledRevocationReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ScheduledRevocationReview, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the scheduled revocation review steps in order and keeps a trace of each.
    final class ScheduledRevocationReviewEngine {
        var steps: [any ScheduledRevocationReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRevocationReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledRevocationReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRevocationReviewStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledRevocationReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledRevocationReviewEngine(_ flags: Kit.Flags.Registry) -> ScheduledRevocationReviewEngine {
        return ScheduledRevocationReviewEngine(
            steps: [
                FlaggedScheduledRevocationReviewAdjuster(
                    flags: flags,
                    flag: "scheduled-revocation-review-regional",
                    percent: 6.6
                ),
                TieredScheduledRevocationReviewAdjuster(bounds: [9585.0, 9982.0], rates: [1.13, 1.01]),
                ScheduledRevocationReviewCeilingOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 6720.4
        )
    }
}
