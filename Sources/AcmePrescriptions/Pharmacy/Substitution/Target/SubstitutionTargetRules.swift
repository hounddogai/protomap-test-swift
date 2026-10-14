import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution target must pass. Check returns its problems, or none.
    protocol SubstitutionTargetRule {
        func check(_ item: SubstitutionTarget) -> [String]
    }

    final class SubstitutionTargetRequiredNameRule: SubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionTargetRequiredNotesRule: SubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionTarget) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionTargetRequiredLabelRule: SubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution target.
    final class SubstitutionTargetValidator {
        var rules: [any SubstitutionTargetRule]

        init(rules: [any SubstitutionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionTarget) -> [String] {
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

        func requireValid(_ item: SubstitutionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionTarget]) -> [String: [String]] {
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

    static func defaultSubstitutionTargetValidator() -> SubstitutionTargetValidator {
        return SubstitutionTargetValidator(
            rules: [
                SubstitutionTargetRequiredNameRule(message: "substitution target needs an entry"),
                SubstitutionTargetRequiredNotesRule(message: "substitution target needs a value"),
                SubstitutionTargetRequiredLabelRule(message: "substitution target needs an entry"),
            ]
        )
    }
}
