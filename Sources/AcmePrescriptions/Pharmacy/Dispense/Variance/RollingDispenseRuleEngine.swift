import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling dispense rule calculation.
    protocol RollingDispenseRuleFactor {
        func describe() -> String
        func adjust(_ item: RollingDispenseRule, value: Double) -> Double
    }

    final class LabelRollingDispenseRuleAdjuster: RollingDispenseRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingDispenseRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingDispenseRuleAdjuster: RollingDispenseRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDispenseRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingDispenseRuleAdjuster: RollingDispenseRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingDispenseRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingDispenseRuleAdjuster: RollingDispenseRuleFactor {
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

        func adjust(_ item: RollingDispenseRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling dispense rule steps in order and keeps a trace of each.
    final class RollingDispenseRuleEngine {
        var steps: [any RollingDispenseRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDispenseRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingDispenseRule) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [RollingDispenseRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingDispenseRuleEngine(_ flags: Kit.Flags.Registry) -> RollingDispenseRuleEngine {
        return RollingDispenseRuleEngine(
            steps: [
                LabelRollingDispenseRuleAdjuster(factors: ["west": 1.39, "online": 0.7, "south": 1.39]),
                RoundingRollingDispenseRuleAdjuster(step: 0.05),
                MinimumRollingDispenseRuleAdjuster(minimum: 5.2),
                FlaggedRollingDispenseRuleAdjuster(
                    flags: flags,
                    flag: "rolling-dispense-rule-seasonal",
                    percent: -9.1
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 59338.6
        )
    }
}
