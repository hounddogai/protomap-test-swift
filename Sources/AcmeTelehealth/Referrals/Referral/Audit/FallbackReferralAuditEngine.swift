import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback referral audit calculation.
    protocol FallbackReferralAuditModifier {
        func describe() -> String
        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double
    }

    final class FlaggedFallbackReferralAuditAdjuster: FallbackReferralAuditModifier {
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

        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackReferralAuditAdjuster: FallbackReferralAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackReferralAuditAdjuster: FallbackReferralAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackReferralAuditAdjuster: FallbackReferralAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackReferralAuditAdjuster: FallbackReferralAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackReferralAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback referral audit steps in order and keeps a trace of each.
    final class FallbackReferralAuditEngine {
        var steps: [any FallbackReferralAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferralAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackReferralAudit) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackReferralAuditModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackReferralAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackReferralAuditEngine(_ flags: Kit.Flags.Registry) -> FallbackReferralAuditEngine {
        return FallbackReferralAuditEngine(
            steps: [
                FlaggedFallbackReferralAuditAdjuster(
                    flags: flags,
                    flag: "fallback-referral-audit-pending",
                    percent: -4.7
                ),
                RoundingFallbackReferralAuditAdjuster(step: 1.0),
                TieredFallbackReferralAuditAdjuster(bounds: [6463.0, 6533.0], rates: [1.04, 1.13]),
                MinimumFallbackReferralAuditAdjuster(minimum: 40.2),
                PercentFallbackReferralAuditAdjuster(percent: 12.2),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 49872.3
        )
    }
}
