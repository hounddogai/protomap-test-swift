import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient statement rule calculation.
    protocol LenientStatementRuleFactor {
        func describe() -> String
        func adjust(_ item: LenientStatementRule, value: Double) -> Double
    }

    final class PercentLenientStatementRuleAdjuster: LenientStatementRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientStatementRuleAdjuster: LenientStatementRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelLenientStatementRuleAdjuster: LenientStatementRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientStatementRuleAdjuster: LenientStatementRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientStatementRuleAdjuster: LenientStatementRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientStatementRuleAdjuster: LenientStatementRuleFactor {
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

        func adjust(_ item: LenientStatementRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient statement rule steps in order and keeps a trace of each.
    final class LenientStatementRuleEngine {
        var steps: [any LenientStatementRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientStatementRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientStatementRule) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientStatementRuleFactor = steps[index]
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

        func evaluateAll(_ items: [LenientStatementRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientStatementRuleEngine(_ flags: Kit.Flags.Registry) -> LenientStatementRuleEngine {
        return LenientStatementRuleEngine(
            steps: [
                PercentLenientStatementRuleAdjuster(percent: 23.2),
                TieredLenientStatementRuleAdjuster(
                    bounds: [1434.0, 2713.0, 4210.0, 4597.0],
                    rates: [0.83, 0.99, 0.98, 1.02]
                ),
                LabelLenientStatementRuleAdjuster(factors: ["east": 1.3, "south": 1.04]),
                MinimumLenientStatementRuleAdjuster(minimum: 44.1),
                CapLenientStatementRuleAdjuster(cap: 9105.0),
                FlaggedLenientStatementRuleAdjuster(
                    flags: flags,
                    flag: "lenient-statement-rule-weighted",
                    percent: -1.8
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 15415.2
        )
    }
}
