import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution rule must pass. Check returns its problems, or none.
    protocol SubstitutionRuleRule {
        func check(_ item: SubstitutionRule) -> [String]
    }

    final class SubstitutionRuleAllowedTitleRule: SubstitutionRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class SubstitutionRuleCodePrefixRule: SubstitutionRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionRuleRequiredNotesRule: SubstitutionRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRule) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution rule.
    final class SubstitutionRuleValidator {
        var rules: [any SubstitutionRuleRule]

        init(rules: [any SubstitutionRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionRule]) -> [String: [String]] {
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

    static func defaultSubstitutionRuleValidator() -> SubstitutionRuleValidator {
        return SubstitutionRuleValidator(
            rules: [
                SubstitutionRuleAllowedTitleRule(allowed: []),
                SubstitutionRuleCodePrefixRule(prefix: "OPS"),
                SubstitutionRuleRequiredNotesRule(message: "substitution rule needs a value"),
            ]
        )
    }
}
