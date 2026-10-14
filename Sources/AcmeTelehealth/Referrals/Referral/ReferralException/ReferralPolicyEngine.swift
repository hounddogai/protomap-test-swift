import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral policy calculation.
    protocol ReferralPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralPolicy, value: Double) -> Double
    }

    final class ReferralPolicyCostOffsetAdjuster: ReferralPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ReferralPolicy, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredReferralPolicyAdjuster: ReferralPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReferralPolicyAdjuster: ReferralPolicyAdjuster {
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

        func adjust(_ item: ReferralPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral policy steps in order and keeps a trace of each.
    final class ReferralPolicyEngine {
        var steps: [any ReferralPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralPolicy) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ReferralPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralPolicyEngine(_ flags: Kit.Flags.Registry) -> ReferralPolicyEngine {
        return ReferralPolicyEngine(
            steps: [
                ReferralPolicyCostOffsetAdjuster(weight: 0.75),
                TieredReferralPolicyAdjuster(bounds: [6311.0, 8200.0, 9257.0], rates: [1.06, 0.85, 1.18]),
                FlaggedReferralPolicyAdjuster(flags: flags, flag: "referral-policy-pending", percent: 8.6),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 73325.1
        )
    }
}
