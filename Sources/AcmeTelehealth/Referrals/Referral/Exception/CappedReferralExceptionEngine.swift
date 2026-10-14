import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped referral exception calculation.
    protocol CappedReferralExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: CappedReferralException, value: Double) -> Double
    }

    final class PercentCappedReferralExceptionAdjuster: CappedReferralExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedReferralException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedReferralExceptionAdjuster: CappedReferralExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedReferralException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedReferralExceptionAdjuster: CappedReferralExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedReferralException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedReferralExceptionVisitMinutesOffsetAdjuster: CappedReferralExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CappedReferralException, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumCappedReferralExceptionAdjuster: CappedReferralExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped referral exception steps in order and keeps a trace of each.
    final class CappedReferralExceptionEngine {
        var steps: [any CappedReferralExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedReferralExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedReferralException) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedReferralExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedReferralExceptionEngine() -> CappedReferralExceptionEngine {
        return CappedReferralExceptionEngine(
            steps: [
                PercentCappedReferralExceptionAdjuster(percent: 10.8),
                CapCappedReferralExceptionAdjuster(cap: 19217.0),
                TieredCappedReferralExceptionAdjuster(bounds: [1108.0, 4845.0, 6215.0], rates: [1.15, 0.9, 1.02]),
                CappedReferralExceptionVisitMinutesOffsetAdjuster(weight: 0.52),
                MinimumCappedReferralExceptionAdjuster(minimum: 0.4),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 34967.3
        )
    }
}
