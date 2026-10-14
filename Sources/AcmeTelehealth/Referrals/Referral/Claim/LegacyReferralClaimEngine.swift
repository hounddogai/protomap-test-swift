import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy referral claim calculation.
    protocol LegacyReferralClaimFactor {
        func describe() -> String
        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double
    }

    final class RoundingLegacyReferralClaimAdjuster: LegacyReferralClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyReferralClaimAdjuster: LegacyReferralClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyReferralClaimAdjuster: LegacyReferralClaimFactor {
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

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyReferralClaimRefillsOffsetAdjuster: LegacyReferralClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class MinimumLegacyReferralClaimAdjuster: LegacyReferralClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyReferralClaimAdjuster: LegacyReferralClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyReferralClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy referral claim steps in order and keeps a trace of each.
    final class LegacyReferralClaimEngine {
        var steps: [any LegacyReferralClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyReferralClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyReferralClaim) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyReferralClaimFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyReferralClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyReferralClaimEngine(_ flags: Kit.Flags.Registry) -> LegacyReferralClaimEngine {
        return LegacyReferralClaimEngine(
            steps: [
                RoundingLegacyReferralClaimAdjuster(step: 1.0),
                PercentLegacyReferralClaimAdjuster(percent: -1.8),
                FlaggedLegacyReferralClaimAdjuster(flags: flags, flag: "legacy-referral-claim-batched", percent: 8.1),
                LegacyReferralClaimRefillsOffsetAdjuster(weight: 0.84),
                MinimumLegacyReferralClaimAdjuster(minimum: 44.1),
                CapLegacyReferralClaimAdjuster(cap: 28618.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 71641.0
        )
    }
}
