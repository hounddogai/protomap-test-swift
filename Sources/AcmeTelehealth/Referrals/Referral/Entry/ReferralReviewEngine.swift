import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral review calculation.
    protocol ReferralReviewFactor {
        func describe() -> String
        func adjust(_ item: ReferralReview, value: Double) -> Double
    }

    final class MinimumReferralReviewAdjuster: ReferralReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralReviewAdjuster: ReferralReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentReferralReviewAdjuster: ReferralReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardReferralReviewAdjuster: ReferralReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ReferralReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingReferralReviewAdjuster: ReferralReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the referral review steps in order and keeps a trace of each.
    final class ReferralReviewEngine {
        var steps: [any ReferralReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralReview) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralReviewFactor = steps[index]
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

        func evaluateAll(_ items: [ReferralReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralReviewEngine() -> ReferralReviewEngine {
        return ReferralReviewEngine(
            steps: [
                MinimumReferralReviewAdjuster(minimum: 17.4),
                TieredReferralReviewAdjuster(bounds: [1840.0, 5856.0, 8636.0], rates: [1.0, 0.93, 0.92]),
                PercentReferralReviewAdjuster(percent: 4.1),
                WardReferralReviewAdjuster(factors: ["online": 0.86, "east": 0.99, "retail": 0.95]),
                RoundingReferralReviewAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 53975.5
        )
    }
}
