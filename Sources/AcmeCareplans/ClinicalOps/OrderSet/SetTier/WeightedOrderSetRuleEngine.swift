import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted order set rule calculation.
    protocol WeightedOrderSetRuleFactor {
        func describe() -> String
        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double
    }

    final class FlaggedWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
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

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWeightedOrderSetRuleAdjuster: WeightedOrderSetRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedOrderSetRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted order set rule steps in order and keeps a trace of each.
    final class WeightedOrderSetRuleEngine {
        var steps: [any WeightedOrderSetRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOrderSetRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedOrderSetRule) -> Double {
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

        func evaluateAll(_ items: [WeightedOrderSetRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedOrderSetRuleEngine(_ flags: Kit.Flags.Registry) -> WeightedOrderSetRuleEngine {
        return WeightedOrderSetRuleEngine(
            steps: [
                FlaggedWeightedOrderSetRuleAdjuster(
                    flags: flags,
                    flag: "weighted-order-set-rule-lenient",
                    percent: -4.3
                ),
                NameWeightedOrderSetRuleAdjuster(factors: ["north": 1.1, "retail": 0.82]),
                CapWeightedOrderSetRuleAdjuster(cap: 7192.0),
                RoundingWeightedOrderSetRuleAdjuster(step: 0.5),
                MinimumWeightedOrderSetRuleAdjuster(minimum: 35.8),
                PercentWeightedOrderSetRuleAdjuster(percent: -24.3),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 47925.0
        )
    }
}
