import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual rounding rule must pass. Check returns its problems, or none.
    protocol ManualRoundingRuleRule {
        func check(_ item: ManualRoundingRule) -> [String]
    }

    final class ManualRoundingRuleCodeLengthRule: ManualRoundingRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRoundingRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRoundingRuleTitleLengthRule: ManualRoundingRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRoundingRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRoundingRuleCeilingRangeRule: ManualRoundingRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRoundingRule) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualRoundingRuleRequiredPhoneRule: ManualRoundingRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual rounding rule.
    final class ManualRoundingRuleValidator {
        var rules: [any ManualRoundingRuleRule]

        init(rules: [any ManualRoundingRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRoundingRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRoundingRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRoundingRule]) -> [String: [String]] {
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

    static func defaultManualRoundingRuleValidator() -> ManualRoundingRuleValidator {
        return ManualRoundingRuleValidator(
            rules: [
                ManualRoundingRuleCodeLengthRule(maxLength: 86400),
                ManualRoundingRuleTitleLengthRule(maxLength: 64),
                ManualRoundingRuleCeilingRangeRule(min: 2.1, max: 1533.3),
                ManualRoundingRuleRequiredPhoneRule(message: "manual rounding rule needs an entry"),
            ]
        )
    }
}
