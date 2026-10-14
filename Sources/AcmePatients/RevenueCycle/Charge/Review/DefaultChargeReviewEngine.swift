import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge review calculation.
    protocol DefaultChargeReviewAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultChargeReview, value: Double) -> Double
    }

    final class TieredDefaultChargeReviewAdjuster: DefaultChargeReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultChargeReviewAdjuster: DefaultChargeReviewAdjuster {
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

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultChargeReviewAdjuster: DefaultChargeReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardDefaultChargeReviewAdjuster: DefaultChargeReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultChargeReviewAdjuster: DefaultChargeReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DefaultChargeReviewRateOffsetAdjuster: DefaultChargeReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: DefaultChargeReview, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the default charge review steps in order and keeps a trace of each.
    final class DefaultChargeReviewEngine {
        var steps: [any DefaultChargeReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultChargeReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultChargeReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultChargeReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeReviewEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeReviewEngine {
        return DefaultChargeReviewEngine(
            steps: [
                TieredDefaultChargeReviewAdjuster(bounds: [6982.0, 7359.0], rates: [1.06, 0.88]),
                FlaggedDefaultChargeReviewAdjuster(flags: flags, flag: "default-charge-review-weighted", percent: 6.7),
                RoundingDefaultChargeReviewAdjuster(step: 5.0),
                WardDefaultChargeReviewAdjuster(factors: ["central": 1.12, "west": 1.36, "east": 1.28]),
                CapDefaultChargeReviewAdjuster(cap: 30885.0),
                DefaultChargeReviewRateOffsetAdjuster(weight: 1.2),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 38385.2
        )
    }
}
