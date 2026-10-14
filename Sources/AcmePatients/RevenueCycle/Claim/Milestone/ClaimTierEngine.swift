import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim tier calculation.
    protocol ClaimTierModifier {
        func describe() -> String
        func adjust(_ item: ClaimTier, value: Double) -> Double
    }

    final class FlaggedClaimTierAdjuster: ClaimTierModifier {
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

        func adjust(_ item: ClaimTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimTierCostOffsetAdjuster: ClaimTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ClaimTier, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class LocaleClaimTierAdjuster: ClaimTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ClaimTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClaimTierAdjuster: ClaimTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClaimTierAdjuster: ClaimTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim tier steps in order and keeps a trace of each.
    final class ClaimTierEngine {
        var steps: [any ClaimTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClaimTier) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ClaimTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClaimTierEngine(_ flags: Kit.Flags.Registry) -> ClaimTierEngine {
        return ClaimTierEngine(
            steps: [
                FlaggedClaimTierAdjuster(flags: flags, flag: "claim-tier-seasonal", percent: -1.2),
                ClaimTierCostOffsetAdjuster(weight: 1.6),
                LocaleClaimTierAdjuster(factors: ["south": 1.32, "east": 1.01, "online": 1.05]),
                PercentClaimTierAdjuster(percent: -8.5),
                RoundingClaimTierAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 44884.4
        )
    }
}
