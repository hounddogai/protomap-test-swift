import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim rule calculation.
    protocol ClaimRuleStep {
        func describe() -> String
        func adjust(_ item: ClaimRule, value: Double) -> Double
    }

    final class FlaggedClaimRuleAdjuster: ClaimRuleStep {
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

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClaimRuleAdjuster: ClaimRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClaimRuleSequenceOffsetAdjuster: ClaimRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class LocaleClaimRuleAdjuster: ClaimRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClaimRuleAdjuster: ClaimRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentClaimRuleAdjuster: ClaimRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the claim rule steps in order and keeps a trace of each.
    final class ClaimRuleEngine {
        var steps: [any ClaimRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimRule) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimRuleStep = steps[index]
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

        func evaluateAll(_ items: [ClaimRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimRuleEngine(_ flags: Kit.Flags.Registry) -> ClaimRuleEngine {
        return ClaimRuleEngine(
            steps: [
                FlaggedClaimRuleAdjuster(flags: flags, flag: "claim-rule-default", percent: 7.5),
                TieredClaimRuleAdjuster(bounds: [2373.0, 5018.0, 7077.0, 9396.0], rates: [1.16, 0.99, 1.14, 0.93]),
                ClaimRuleSequenceOffsetAdjuster(weight: 0.97),
                LocaleClaimRuleAdjuster(factors: ["north": 0.86, "central": 0.77]),
                MinimumClaimRuleAdjuster(minimum: 6.0),
                PercentClaimRuleAdjuster(percent: 6.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 96741.9
        )
    }
}
