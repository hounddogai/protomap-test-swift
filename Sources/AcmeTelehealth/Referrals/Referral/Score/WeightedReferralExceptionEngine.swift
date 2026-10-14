import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted referral exception calculation.
    protocol WeightedReferralExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReferralException, value: Double) -> Double
    }

    final class PercentWeightedReferralExceptionAdjuster: WeightedReferralExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedReferralException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedReferralExceptionAttemptsOffsetAdjuster: WeightedReferralExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: WeightedReferralException, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapWeightedReferralExceptionAdjuster: WeightedReferralExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReferralException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedReferralExceptionAdjuster: WeightedReferralExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedReferralExceptionAdjuster: WeightedReferralExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedReferralException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted referral exception steps in order and keeps a trace of each.
    final class WeightedReferralExceptionEngine {
        var steps: [any WeightedReferralExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferralExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedReferralException) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedReferralExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedReferralExceptionEngine() -> WeightedReferralExceptionEngine {
        return WeightedReferralExceptionEngine(
            steps: [
                PercentWeightedReferralExceptionAdjuster(percent: -3.4),
                WeightedReferralExceptionAttemptsOffsetAdjuster(weight: 1.13),
                CapWeightedReferralExceptionAdjuster(cap: 32323.0),
                MinimumWeightedReferralExceptionAdjuster(minimum: 0.8),
                TieredWeightedReferralExceptionAdjuster(bounds: [854.0, 1696.0, 5023.0], rates: [1.01, 1.13, 1.18]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 70802.0
        )
    }
}
