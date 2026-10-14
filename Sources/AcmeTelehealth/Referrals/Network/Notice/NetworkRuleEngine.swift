import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network rule calculation.
    protocol NetworkRuleFactor {
        func describe() -> String
        func adjust(_ item: NetworkRule, value: Double) -> Double
    }

    final class CapNetworkRuleAdjuster: NetworkRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryNetworkRuleAdjuster: NetworkRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: NetworkRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedNetworkRuleAdjuster: NetworkRuleFactor {
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

        func adjust(_ item: NetworkRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkRuleAdjuster: NetworkRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network rule steps in order and keeps a trace of each.
    final class NetworkRuleEngine {
        var steps: [any NetworkRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkRule) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [NetworkRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkRuleEngine(_ flags: Kit.Flags.Registry) -> NetworkRuleEngine {
        return NetworkRuleEngine(
            steps: [
                CapNetworkRuleAdjuster(cap: 49424.0),
                CountryNetworkRuleAdjuster(factors: ["retail": 1.03, "east": 1.12]),
                FlaggedNetworkRuleAdjuster(flags: flags, flag: "network-rule-batched", percent: -4.3),
                MinimumNetworkRuleAdjuster(minimum: 7.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 61598.3
        )
    }
}
