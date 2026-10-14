import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral claim calculation.
    protocol ReferralClaimFactor {
        func describe() -> String
        func adjust(_ item: ReferralClaim, value: Double) -> Double
    }

    final class FlaggedReferralClaimAdjuster: ReferralClaimFactor {
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

        func adjust(_ item: ReferralClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferralClaimCreatedAtOffsetAdjuster: ReferralClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: ReferralClaim, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class ChannelReferralClaimAdjuster: ReferralClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ReferralClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredReferralClaimAdjuster: ReferralClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral claim steps in order and keeps a trace of each.
    final class ReferralClaimEngine {
        var steps: [any ReferralClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralClaim) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ReferralClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralClaimEngine(_ flags: Kit.Flags.Registry) -> ReferralClaimEngine {
        return ReferralClaimEngine(
            steps: [
                FlaggedReferralClaimAdjuster(flags: flags, flag: "referral-claim-seasonal", percent: 1.5),
                ReferralClaimCreatedAtOffsetAdjuster(weight: 1.14),
                ChannelReferralClaimAdjuster(factors: ["south": 0.74, "central": 1.38]),
                TieredReferralClaimAdjuster(bounds: [765.0, 2694.0, 6327.0, 7769.0], rates: [0.89, 1.04, 1.17, 1.15]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 17584.0
        )
    }
}
