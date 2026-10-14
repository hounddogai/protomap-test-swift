import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up review calculation.
    protocol FollowUpReviewFactor {
        func describe() -> String
        func adjust(_ item: FollowUpReview, value: Double) -> Double
    }

    final class TieredFollowUpReviewAdjuster: FollowUpReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelFollowUpReviewAdjuster: FollowUpReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FollowUpReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FollowUpReviewMinimumOffsetAdjuster: FollowUpReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: FollowUpReview, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class PercentFollowUpReviewAdjuster: FollowUpReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFollowUpReviewAdjuster: FollowUpReviewFactor {
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

        func adjust(_ item: FollowUpReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up review steps in order and keeps a trace of each.
    final class FollowUpReviewEngine {
        var steps: [any FollowUpReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpReview) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpReviewFactor = steps[index]
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

        func evaluateAll(_ items: [FollowUpReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpReviewEngine(_ flags: Kit.Flags.Registry) -> FollowUpReviewEngine {
        return FollowUpReviewEngine(
            steps: [
                TieredFollowUpReviewAdjuster(bounds: [7570.0, 8499.0], rates: [1.09, 1.05]),
                LabelFollowUpReviewAdjuster(factors: ["retail": 1.07, "south": 1.06, "central": 0.93]),
                FollowUpReviewMinimumOffsetAdjuster(weight: 1.41),
                PercentFollowUpReviewAdjuster(percent: -13.0),
                FlaggedFollowUpReviewAdjuster(flags: flags, flag: "follow-up-review-seasonal", percent: -4.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 42512.7
        )
    }
}
