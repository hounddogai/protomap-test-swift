import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted referral audit calculation.
    protocol WeightedReferralAuditStep {
        func describe() -> String
        func adjust(_ item: WeightedReferralAudit, value: Double) -> Double
    }

    final class RoundingWeightedReferralAuditAdjuster: WeightedReferralAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReferralAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedReferralAuditAdjuster: WeightedReferralAuditStep {
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

        func adjust(_ item: WeightedReferralAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedReferralAuditAdjuster: WeightedReferralAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReferralAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted referral audit steps in order and keeps a trace of each.
    final class WeightedReferralAuditEngine {
        var steps: [any WeightedReferralAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferralAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedReferralAudit) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [WeightedReferralAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedReferralAuditEngine(_ flags: Kit.Flags.Registry) -> WeightedReferralAuditEngine {
        return WeightedReferralAuditEngine(
            steps: [
                RoundingWeightedReferralAuditAdjuster(step: 0.1),
                FlaggedWeightedReferralAuditAdjuster(
                    flags: flags,
                    flag: "weighted-referral-audit-batched",
                    percent: 2.4
                ),
                MinimumWeightedReferralAuditAdjuster(minimum: 4.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 42763.5
        )
    }
}
