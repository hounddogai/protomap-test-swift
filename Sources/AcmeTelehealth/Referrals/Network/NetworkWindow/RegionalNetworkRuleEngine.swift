import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional network rule calculation.
    protocol RegionalNetworkRuleStep {
        func describe() -> String
        func adjust(_ item: RegionalNetworkRule, value: Double) -> Double
    }

    final class PercentRegionalNetworkRuleAdjuster: RegionalNetworkRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalNetworkRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRegionalNetworkRuleAdjuster: RegionalNetworkRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalNetworkRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalNetworkRuleAdjuster: RegionalNetworkRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalNetworkRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalNetworkRuleAdjuster: RegionalNetworkRuleStep {
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

        func adjust(_ item: RegionalNetworkRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional network rule steps in order and keeps a trace of each.
    final class RegionalNetworkRuleEngine {
        var steps: [any RegionalNetworkRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalNetworkRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalNetworkRule) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RegionalNetworkRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalNetworkRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalNetworkRuleEngine {
        return RegionalNetworkRuleEngine(
            steps: [
                PercentRegionalNetworkRuleAdjuster(percent: -10.0),
                TitleRegionalNetworkRuleAdjuster(factors: ["central": 0.72, "south": 0.73, "west": 1.37]),
                RoundingRegionalNetworkRuleAdjuster(step: 1.0),
                FlaggedRegionalNetworkRuleAdjuster(flags: flags, flag: "regional-network-rule-pending", percent: -0.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 36825.2
        )
    }
}
