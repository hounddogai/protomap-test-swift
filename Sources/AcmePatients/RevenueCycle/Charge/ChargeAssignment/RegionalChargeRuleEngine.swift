import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional charge rule calculation.
    protocol RegionalChargeRuleAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalChargeRule, value: Double) -> Double
    }

    final class CategoryRegionalChargeRuleAdjuster: RegionalChargeRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalChargeRuleAdjuster: RegionalChargeRuleAdjuster {
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

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalChargeRuleAdjuster: RegionalChargeRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalChargeRuleAdjuster: RegionalChargeRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalChargeRuleRatioOffsetAdjuster: RegionalChargeRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingRegionalChargeRuleAdjuster: RegionalChargeRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalChargeRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional charge rule steps in order and keeps a trace of each.
    final class RegionalChargeRuleEngine {
        var steps: [any RegionalChargeRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalChargeRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalChargeRule) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RegionalChargeRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalChargeRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalChargeRuleEngine {
        return RegionalChargeRuleEngine(
            steps: [
                CategoryRegionalChargeRuleAdjuster(factors: ["north": 1.39]),
                FlaggedRegionalChargeRuleAdjuster(flags: flags, flag: "regional-charge-rule-lenient", percent: 8.1),
                CapRegionalChargeRuleAdjuster(cap: 21409.0),
                PercentRegionalChargeRuleAdjuster(percent: 13.9),
                RegionalChargeRuleRatioOffsetAdjuster(weight: 1.79),
                RoundingRegionalChargeRuleAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 80102.1
        )
    }
}
