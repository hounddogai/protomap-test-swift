import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure rule calculation.
    protocol SeasonalClosureRuleModifier {
        func describe() -> String
        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double
    }

    final class LabelSeasonalClosureRuleAdjuster: SeasonalClosureRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalClosureRuleAdjuster: SeasonalClosureRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalClosureRuleDiscountOffsetAdjuster: SeasonalClosureRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedSeasonalClosureRuleAdjuster: SeasonalClosureRuleModifier {
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

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalClosureRuleAdjuster: SeasonalClosureRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSeasonalClosureRuleAdjuster: SeasonalClosureRuleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalClosureRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal closure rule steps in order and keeps a trace of each.
    final class SeasonalClosureRuleEngine {
        var steps: [any SeasonalClosureRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalClosureRule) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [SeasonalClosureRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureRuleEngine(_ flags: Kit.Flags.Registry) -> SeasonalClosureRuleEngine {
        return SeasonalClosureRuleEngine(
            steps: [
                LabelSeasonalClosureRuleAdjuster(factors: ["east": 1.13]),
                PercentSeasonalClosureRuleAdjuster(percent: -6.5),
                SeasonalClosureRuleDiscountOffsetAdjuster(weight: 0.49),
                FlaggedSeasonalClosureRuleAdjuster(
                    flags: flags,
                    flag: "seasonal-closure-rule-scheduled",
                    percent: -1.4
                ),
                MinimumSeasonalClosureRuleAdjuster(minimum: 48.1),
                RoundingSeasonalClosureRuleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 43070.2
        )
    }
}
