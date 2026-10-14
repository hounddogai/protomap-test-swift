import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback accession review calculation.
    protocol FallbackAccessionReviewFactor {
        func describe() -> String
        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double
    }

    final class FallbackAccessionReviewDiscountOffsetAdjuster: FallbackAccessionReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentFallbackAccessionReviewAdjuster: FallbackAccessionReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackAccessionReviewAdjuster: FallbackAccessionReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackAccessionReviewAdjuster: FallbackAccessionReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackAccessionReviewAdjuster: FallbackAccessionReviewFactor {
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

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackAccessionReviewAdjuster: FallbackAccessionReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAccessionReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback accession review steps in order and keeps a trace of each.
    final class FallbackAccessionReviewEngine {
        var steps: [any FallbackAccessionReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAccessionReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAccessionReview) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAccessionReviewFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackAccessionReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAccessionReviewEngine(_ flags: Kit.Flags.Registry) -> FallbackAccessionReviewEngine {
        return FallbackAccessionReviewEngine(
            steps: [
                FallbackAccessionReviewDiscountOffsetAdjuster(weight: 0.28),
                PercentFallbackAccessionReviewAdjuster(percent: -23.1),
                CapFallbackAccessionReviewAdjuster(cap: 28556.0),
                TieredFallbackAccessionReviewAdjuster(bounds: [1606.0, 7846.0], rates: [1.1, 1.05]),
                FlaggedFallbackAccessionReviewAdjuster(
                    flags: flags,
                    flag: "fallback-accession-review-scheduled",
                    percent: 8.4
                ),
                RoundingFallbackAccessionReviewAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 76240.3
        )
    }
}
