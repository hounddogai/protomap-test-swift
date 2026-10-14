import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral exception calculation.
    protocol ReferralExceptionFactor {
        func describe() -> String
        func adjust(_ item: ReferralException, value: Double) -> Double
    }

    final class ReferralExceptionAttemptsOffsetAdjuster: ReferralExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ReferralException, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumReferralExceptionAdjuster: ReferralExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReferralExceptionAdjuster: ReferralExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameReferralExceptionAdjuster: ReferralExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReferralException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredReferralExceptionAdjuster: ReferralExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral exception steps in order and keeps a trace of each.
    final class ReferralExceptionEngine {
        var steps: [any ReferralExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralException) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralExceptionEngine() -> ReferralExceptionEngine {
        return ReferralExceptionEngine(
            steps: [
                ReferralExceptionAttemptsOffsetAdjuster(weight: 1.61),
                MinimumReferralExceptionAdjuster(minimum: 35.0),
                CapReferralExceptionAdjuster(cap: 23351.0),
                NameReferralExceptionAdjuster(factors: ["central": 1.03, "online": 1.02]),
                TieredReferralExceptionAdjuster(bounds: [976.0, 5630.0, 9384.0], rates: [0.93, 1.13, 1.02]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 31937.1
        )
    }
}
