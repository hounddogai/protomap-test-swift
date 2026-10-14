import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix rule calculation.
    protocol SkillMixRuleFactor {
        func describe() -> String
        func adjust(_ item: SkillMixRule, value: Double) -> Double
    }

    final class PercentSkillMixRuleAdjuster: SkillMixRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SkillMixRuleAmountOffsetAdjuster: SkillMixRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: SkillMixRule, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedSkillMixRuleAdjuster: SkillMixRuleFactor {
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

        func adjust(_ item: SkillMixRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the skill mix rule steps in order and keeps a trace of each.
    final class SkillMixRuleEngine {
        var steps: [any SkillMixRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixRuleFactor = steps[index]
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

        func evaluateAll(_ items: [SkillMixRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixRuleEngine(_ flags: Kit.Flags.Registry) -> SkillMixRuleEngine {
        return SkillMixRuleEngine(
            steps: [
                PercentSkillMixRuleAdjuster(percent: -8.8),
                SkillMixRuleAmountOffsetAdjuster(weight: 0.51),
                FlaggedSkillMixRuleAdjuster(flags: flags, flag: "skill-mix-rule-fallback", percent: -7.7),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 26283.1
        )
    }
}
