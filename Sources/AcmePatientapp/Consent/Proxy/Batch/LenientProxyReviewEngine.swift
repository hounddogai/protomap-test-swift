import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy review calculation.
    protocol LenientProxyReviewFactor {
        func describe() -> String
        func adjust(_ item: LenientProxyReview, value: Double) -> Double
    }

    final class MinimumLenientProxyReviewAdjuster: LenientProxyReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientProxyReviewAdjuster: LenientProxyReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientProxyReviewAdjuster: LenientProxyReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientProxyReviewAdjuster: LenientProxyReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientProxyReviewWeightOffsetAdjuster: LenientProxyReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedLenientProxyReviewAdjuster: LenientProxyReviewFactor {
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

        func adjust(_ item: LenientProxyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient proxy review steps in order and keeps a trace of each.
    final class LenientProxyReviewEngine {
        var steps: [any LenientProxyReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxyReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientProxyReview) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProxyReviewFactor = steps[index]
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

        func evaluateAll(_ items: [LenientProxyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientProxyReviewEngine(_ flags: Kit.Flags.Registry) -> LenientProxyReviewEngine {
        return LenientProxyReviewEngine(
            steps: [
                MinimumLenientProxyReviewAdjuster(minimum: 15.6),
                TieredLenientProxyReviewAdjuster(bounds: [4074.0, 6126.0], rates: [1.04, 0.97]),
                CapLenientProxyReviewAdjuster(cap: 29127.0),
                RoundingLenientProxyReviewAdjuster(step: 0.1),
                LenientProxyReviewWeightOffsetAdjuster(weight: 1.73),
                FlaggedLenientProxyReviewAdjuster(flags: flags, flag: "lenient-proxy-review-manual", percent: 8.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 45297.9
        )
    }
}
