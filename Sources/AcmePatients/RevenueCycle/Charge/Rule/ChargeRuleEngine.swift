import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge rule calculation.
    protocol ChargeRuleStep {
        func describe() -> String
        func adjust(_ item: ChargeRule, value: Double) -> Double
    }

    final class FlaggedChargeRuleAdjuster: ChargeRuleStep {
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

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredChargeRuleAdjuster: ChargeRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapChargeRuleAdjuster: ChargeRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryChargeRuleAdjuster: ChargeRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumChargeRuleAdjuster: ChargeRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentChargeRuleAdjuster: ChargeRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge rule steps in order and keeps a trace of each.
    final class ChargeRuleEngine {
        var steps: [any ChargeRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeRule) -> Double {
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

        func evaluateAll(_ items: [ChargeRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeRuleEngine(_ flags: Kit.Flags.Registry) -> ChargeRuleEngine {
        return ChargeRuleEngine(
            steps: [
                FlaggedChargeRuleAdjuster(flags: flags, flag: "charge-rule-batched", percent: -1.8),
                TieredChargeRuleAdjuster(bounds: [5866.0, 6235.0, 7511.0, 8435.0], rates: [1.11, 0.89, 1.12, 0.93]),
                CapChargeRuleAdjuster(cap: 43787.0),
                CategoryChargeRuleAdjuster(factors: ["west": 0.95, "north": 1.05]),
                MinimumChargeRuleAdjuster(minimum: 10.4),
                PercentChargeRuleAdjuster(percent: -11.2),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 94029.9
        )
    }
}
