import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive referral claim calculation.
    protocol AdaptiveReferralClaimStep {
        func describe() -> String
        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double
    }

    final class UnitAdaptiveReferralClaimAdjuster: AdaptiveReferralClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveReferralClaimSequenceOffsetAdjuster: AdaptiveReferralClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredAdaptiveReferralClaimAdjuster: AdaptiveReferralClaimStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveReferralClaimAdjuster: AdaptiveReferralClaimStep {
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

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveReferralClaimAdjuster: AdaptiveReferralClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveReferralClaimAdjuster: AdaptiveReferralClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveReferralClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive referral claim steps in order and keeps a trace of each.
    final class AdaptiveReferralClaimEngine {
        var steps: [any AdaptiveReferralClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReferralClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveReferralClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveReferralClaimStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveReferralClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReferralClaimEngine(_ flags: Kit.Flags.Registry) -> AdaptiveReferralClaimEngine {
        return AdaptiveReferralClaimEngine(
            steps: [
                UnitAdaptiveReferralClaimAdjuster(factors: ["north": 0.84, "central": 1.31, "online": 0.91]),
                AdaptiveReferralClaimSequenceOffsetAdjuster(weight: 0.47),
                TieredAdaptiveReferralClaimAdjuster(bounds: [39.0, 760.0, 2894.0], rates: [0.81, 0.96, 0.88]),
                FlaggedAdaptiveReferralClaimAdjuster(
                    flags: flags,
                    flag: "adaptive-referral-claim-legacy",
                    percent: -0.4
                ),
                CapAdaptiveReferralClaimAdjuster(cap: 38032.0),
                PercentAdaptiveReferralClaimAdjuster(percent: 6.8),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 83509.2
        )
    }
}
