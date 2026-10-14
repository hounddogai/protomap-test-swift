import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim quota calculation.
    protocol ClaimQuotaModifier {
        func describe() -> String
        func adjust(_ item: ClaimQuota, value: Double) -> Double
    }

    final class ClaimQuotaQuantityOffsetAdjuster: ClaimQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ClaimQuota, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumClaimQuotaAdjuster: ClaimQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClaimQuotaAdjuster: ClaimQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedClaimQuotaAdjuster: ClaimQuotaModifier {
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

        func adjust(_ item: ClaimQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the claim quota steps in order and keeps a trace of each.
    final class ClaimQuotaEngine {
        var steps: [any ClaimQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimQuota) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ClaimQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimQuotaEngine(_ flags: Kit.Flags.Registry) -> ClaimQuotaEngine {
        return ClaimQuotaEngine(
            steps: [
                ClaimQuotaQuantityOffsetAdjuster(weight: 1.6),
                MinimumClaimQuotaAdjuster(minimum: 17.8),
                RoundingClaimQuotaAdjuster(step: 0.5),
                FlaggedClaimQuotaAdjuster(flags: flags, flag: "claim-quota-primary", percent: 4.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 30730.4
        )
    }
}
