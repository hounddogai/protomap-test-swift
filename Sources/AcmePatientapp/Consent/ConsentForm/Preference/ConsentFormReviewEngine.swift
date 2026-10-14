import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form review calculation.
    protocol ConsentFormReviewAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormReview, value: Double) -> Double
    }

    final class PercentConsentFormReviewAdjuster: ConsentFormReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingConsentFormReviewAdjuster: ConsentFormReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedConsentFormReviewAdjuster: ConsentFormReviewAdjuster {
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

        func adjust(_ item: ConsentFormReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumConsentFormReviewAdjuster: ConsentFormReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the consent form review steps in order and keeps a trace of each.
    final class ConsentFormReviewEngine {
        var steps: [any ConsentFormReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormReview) -> Double {
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

        func evaluateAll(_ items: [ConsentFormReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormReviewEngine(_ flags: Kit.Flags.Registry) -> ConsentFormReviewEngine {
        return ConsentFormReviewEngine(
            steps: [
                PercentConsentFormReviewAdjuster(percent: 2.0),
                RoundingConsentFormReviewAdjuster(step: 0.05),
                FlaggedConsentFormReviewAdjuster(flags: flags, flag: "consent-form-review-default", percent: -5.3),
                MinimumConsentFormReviewAdjuster(minimum: 20.3),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 38557.9
        )
    }
}
