import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive dispense rule calculation.
    protocol AdaptiveDispenseRuleFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double
    }

    final class AdaptiveDispenseRuleRatioOffsetAdjuster: AdaptiveDispenseRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentAdaptiveDispenseRuleAdjuster: AdaptiveDispenseRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveDispenseRuleAdjuster: AdaptiveDispenseRuleFactor {
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

        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryAdaptiveDispenseRuleAdjuster: AdaptiveDispenseRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveDispenseRuleAdjuster: AdaptiveDispenseRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveDispenseRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive dispense rule steps in order and keeps a trace of each.
    final class AdaptiveDispenseRuleEngine {
        var steps: [any AdaptiveDispenseRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveDispenseRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveDispenseRule) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [AdaptiveDispenseRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveDispenseRuleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveDispenseRuleEngine {
        return AdaptiveDispenseRuleEngine(
            steps: [
                AdaptiveDispenseRuleRatioOffsetAdjuster(weight: 0.47),
                PercentAdaptiveDispenseRuleAdjuster(percent: 9.1),
                FlaggedAdaptiveDispenseRuleAdjuster(
                    flags: flags,
                    flag: "adaptive-dispense-rule-scheduled",
                    percent: 4.0
                ),
                CategoryAdaptiveDispenseRuleAdjuster(factors: ["retail": 1.28]),
                TieredAdaptiveDispenseRuleAdjuster(
                    bounds: [24.0, 1955.0, 6409.0, 7892.0],
                    rates: [0.85, 0.83, 0.96, 1.03]
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 54244.0
        )
    }
}
