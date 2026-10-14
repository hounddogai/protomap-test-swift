import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global care protocol rule calculation.
    protocol GlobalCareProtocolRuleModifier {
        func describe() -> String
        func adjust(_ item: GlobalCareProtocolRule, value: Double) -> Double
    }

    final class CategoryGlobalCareProtocolRuleAdjuster: GlobalCareProtocolRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: GlobalCareProtocolRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalCareProtocolRuleAdjuster: GlobalCareProtocolRuleModifier {
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

        func adjust(_ item: GlobalCareProtocolRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalCareProtocolRuleAdjuster: GlobalCareProtocolRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCareProtocolRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalCareProtocolRuleAdjuster: GlobalCareProtocolRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareProtocolRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global care protocol rule steps in order and keeps a trace of each.
    final class GlobalCareProtocolRuleEngine {
        var steps: [any GlobalCareProtocolRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareProtocolRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalCareProtocolRule) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareProtocolRuleModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalCareProtocolRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalCareProtocolRuleEngine(_ flags: Kit.Flags.Registry) -> GlobalCareProtocolRuleEngine {
        return GlobalCareProtocolRuleEngine(
            steps: [
                CategoryGlobalCareProtocolRuleAdjuster(factors: ["west": 1.39]),
                FlaggedGlobalCareProtocolRuleAdjuster(
                    flags: flags,
                    flag: "global-care-protocol-rule-scheduled",
                    percent: -6.3
                ),
                TieredGlobalCareProtocolRuleAdjuster(
                    bounds: [558.0, 2804.0, 5386.0, 9529.0],
                    rates: [1.06, 1.11, 0.91, 0.84]
                ),
                PercentGlobalCareProtocolRuleAdjuster(percent: -16.1),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 52508.5
        )
    }
}
