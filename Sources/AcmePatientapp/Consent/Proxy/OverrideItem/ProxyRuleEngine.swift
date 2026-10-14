import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy rule calculation.
    protocol ProxyRuleFactor {
        func describe() -> String
        func adjust(_ item: ProxyRule, value: Double) -> Double
    }

    final class ProxyRuleCostOffsetAdjuster: ProxyRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ProxyRule, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class FlaggedProxyRuleAdjuster: ProxyRuleFactor {
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

        func adjust(_ item: ProxyRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityProxyRuleAdjuster: ProxyRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ProxyRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy rule steps in order and keeps a trace of each.
    final class ProxyRuleEngine {
        var steps: [any ProxyRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProxyRule) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ProxyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProxyRuleEngine(_ flags: Kit.Flags.Registry) -> ProxyRuleEngine {
        return ProxyRuleEngine(
            steps: [
                ProxyRuleCostOffsetAdjuster(weight: 0.81),
                FlaggedProxyRuleAdjuster(flags: flags, flag: "proxy-rule-seasonal", percent: -9.8),
                FacilityProxyRuleAdjuster(factors: ["retail": 1.08, "central": 1.16]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 62813.8
        )
    }
}
