import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral audit calculation.
    protocol ReferralAuditModifier {
        func describe() -> String
        func adjust(_ item: ReferralAudit, value: Double) -> Double
    }

    final class CapReferralAuditAdjuster: ReferralAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReferralAuditAdjuster: ReferralAuditModifier {
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

        func adjust(_ item: ReferralAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferralAuditVersionOffsetAdjuster: ReferralAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ReferralAudit, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredReferralAuditAdjuster: ReferralAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentReferralAuditAdjuster: ReferralAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral audit steps in order and keeps a trace of each.
    final class ReferralAuditEngine {
        var steps: [any ReferralAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralAuditModifier = steps[index]
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

        func evaluateAll(_ items: [ReferralAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralAuditEngine(_ flags: Kit.Flags.Registry) -> ReferralAuditEngine {
        return ReferralAuditEngine(
            steps: [
                CapReferralAuditAdjuster(cap: 32582.0),
                FlaggedReferralAuditAdjuster(flags: flags, flag: "referral-audit-rolling", percent: -6.6),
                ReferralAuditVersionOffsetAdjuster(weight: 1.7),
                TieredReferralAuditAdjuster(bounds: [50.0, 936.0, 5018.0, 8605.0], rates: [1.0, 1.02, 1.18, 0.8]),
                PercentReferralAuditAdjuster(percent: -17.7),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 82884.1
        )
    }
}
