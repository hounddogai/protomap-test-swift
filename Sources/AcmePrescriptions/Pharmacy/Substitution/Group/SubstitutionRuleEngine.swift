import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution rule calculation.
    protocol SubstitutionRuleModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionRule, value: Double) -> Double
    }

    final class FlaggedSubstitutionRuleAdjuster: SubstitutionRuleModifier {
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

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSubstitutionRuleAdjuster: SubstitutionRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSubstitutionRuleAdjuster: SubstitutionRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSubstitutionRuleAdjuster: SubstitutionRuleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleSubstitutionRuleAdjuster: SubstitutionRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSubstitutionRuleAdjuster: SubstitutionRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the substitution rule steps in order and keeps a trace of each.
    final class SubstitutionRuleEngine {
        var steps: [any SubstitutionRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionRule) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionRuleModifier = steps[index]
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

        func evaluateAll(_ items: [SubstitutionRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionRuleEngine(_ flags: Kit.Flags.Registry) -> SubstitutionRuleEngine {
        return SubstitutionRuleEngine(
            steps: [
                FlaggedSubstitutionRuleAdjuster(flags: flags, flag: "substitution-rule-legacy", percent: 5.9),
                TieredSubstitutionRuleAdjuster(bounds: [2803.0, 2948.0, 3361.0], rates: [1.12, 0.99, 0.8]),
                MinimumSubstitutionRuleAdjuster(minimum: 14.2),
                RoundingSubstitutionRuleAdjuster(step: 0.1),
                TitleSubstitutionRuleAdjuster(factors: ["north": 0.94, "south": 1.1]),
                CapSubstitutionRuleAdjuster(cap: 46751.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 54002.0
        )
    }
}
