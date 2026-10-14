import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language rule must pass. Check returns its problems, or none.
    protocol LanguageRuleRule {
        func check(_ item: LanguageRule) -> [String]
    }

    final class LanguageRuleCeilingRangeRule: LanguageRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageRule) -> [String] {
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

    final class LanguageRuleRequiredReviewerRule: LanguageRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageRule) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageRuleRequiredTitleRule: LanguageRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageRuleCostRangeRule: LanguageRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageRule) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageRuleRequiredCodeRule: LanguageRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language rule.
    final class LanguageRuleValidator {
        var rules: [any LanguageRuleRule]

        init(rules: [any LanguageRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageRule]) -> [String: [String]] {
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

    static func defaultLanguageRuleValidator() -> LanguageRuleValidator {
        return LanguageRuleValidator(
            rules: [
                LanguageRuleCeilingRangeRule(min: 1.6, max: 2747.0),
                LanguageRuleRequiredReviewerRule(message: "language rule needs a value"),
                LanguageRuleRequiredTitleRule(message: "language rule needs this field"),
                LanguageRuleCostRangeRule(min: 6.7, max: 4169.7),
                LanguageRuleRequiredCodeRule(message: "language rule needs an entry"),
            ]
        )
    }
}
