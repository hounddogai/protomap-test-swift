import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap review calculation.
    protocol CareGapReviewFactor {
        func describe() -> String
        func adjust(_ item: CareGapReview, value: Double) -> Double
    }

    final class LabelCareGapReviewAdjuster: CareGapReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareGapReviewAdjuster: CareGapReviewFactor {
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

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareGapReviewAdjuster: CareGapReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareGapReviewAdjuster: CareGapReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapReviewAdjuster: CareGapReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareGapReviewAdjuster: CareGapReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care gap review steps in order and keeps a trace of each.
    final class CareGapReviewEngine {
        var steps: [any CareGapReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareGapReview) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapReviewFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareGapReviewEngine(_ flags: Kit.Flags.Registry) -> CareGapReviewEngine {
        return CareGapReviewEngine(
            steps: [
                LabelCareGapReviewAdjuster(factors: ["south": 0.74]),
                FlaggedCareGapReviewAdjuster(flags: flags, flag: "care-gap-review-scheduled", percent: -5.7),
                RoundingCareGapReviewAdjuster(step: 1.0),
                PercentCareGapReviewAdjuster(percent: 5.4),
                TieredCareGapReviewAdjuster(bounds: [2482.0, 7397.0, 8378.0, 9345.0], rates: [0.89, 0.99, 0.9, 0.95]),
                MinimumCareGapReviewAdjuster(minimum: 1.5),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 90393.1
        )
    }
}
