import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix rule must pass. Check returns its problems, or none.
    protocol SkillMixRuleRule {
        func check(_ item: SkillMixRule) -> [String]
    }

    final class SkillMixRuleAmountRangeRule: SkillMixRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixRule) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixRuleCodePrefixRule: SkillMixRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixRuleCodeLengthRule: SkillMixRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix rule.
    final class SkillMixRuleValidator {
        var rules: [any SkillMixRuleRule]

        init(rules: [any SkillMixRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixRule]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultSkillMixRuleValidator() -> SkillMixRuleValidator {
        return SkillMixRuleValidator(
            rules: [
                SkillMixRuleAmountRangeRule(min: 4.0, max: 818.1),
                SkillMixRuleCodePrefixRule(prefix: "Q"),
                SkillMixRuleCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
