import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global specimen rule calculation.
    protocol GlobalSpecimenRuleStep {
        func describe() -> String
        func adjust(_ item: GlobalSpecimenRule, value: Double) -> Double
    }

    final class TitleGlobalSpecimenRuleAdjuster: GlobalSpecimenRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalSpecimenRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalSpecimenRuleAdjuster: GlobalSpecimenRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalSpecimenRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalSpecimenRuleAdjuster: GlobalSpecimenRuleStep {
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

        func adjust(_ item: GlobalSpecimenRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalSpecimenRuleAdjuster: GlobalSpecimenRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSpecimenRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global specimen rule steps in order and keeps a trace of each.
    final class GlobalSpecimenRuleEngine {
        var steps: [any GlobalSpecimenRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSpecimenRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalSpecimenRule) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSpecimenRuleStep = steps[index]
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

        func evaluateAll(_ items: [GlobalSpecimenRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalSpecimenRuleEngine(_ flags: Kit.Flags.Registry) -> GlobalSpecimenRuleEngine {
        return GlobalSpecimenRuleEngine(
            steps: [
                TitleGlobalSpecimenRuleAdjuster(factors: ["north": 1.36, "central": 1.04, "retail": 1.1]),
                CapGlobalSpecimenRuleAdjuster(cap: 44536.0),
                FlaggedGlobalSpecimenRuleAdjuster(flags: flags, flag: "global-specimen-rule-adaptive", percent: 9.3),
                RoundingGlobalSpecimenRuleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 84592.8
        )
    }
}
