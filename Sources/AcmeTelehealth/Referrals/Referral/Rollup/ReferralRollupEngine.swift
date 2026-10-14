import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral rollup calculation.
    protocol ReferralRollupFactor {
        func describe() -> String
        func adjust(_ item: ReferralRollup, value: Double) -> Double
    }

    final class TieredReferralRollupAdjuster: ReferralRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentReferralRollupAdjuster: ReferralRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferralRollupRateOffsetAdjuster: ReferralRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ReferralRollup, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the referral rollup steps in order and keeps a trace of each.
    final class ReferralRollupEngine {
        var steps: [any ReferralRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferralRollup) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ReferralRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferralRollupEngine() -> ReferralRollupEngine {
        return ReferralRollupEngine(
            steps: [
                TieredReferralRollupAdjuster(bounds: [879.0, 2546.0, 2633.0, 3670.0], rates: [0.89, 0.87, 1.13, 1.0]),
                PercentReferralRollupAdjuster(percent: -7.5),
                ReferralRollupRateOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 14180.3
        )
    }
}
