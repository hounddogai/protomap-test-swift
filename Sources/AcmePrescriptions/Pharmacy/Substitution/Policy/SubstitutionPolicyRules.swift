import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution policy must pass. Check returns its problems, or none.
    protocol SubstitutionPolicyRule {
        func check(_ item: SubstitutionPolicy) -> [String]
    }

    final class SubstitutionPolicyRequiredSpecialtyRule: SubstitutionPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionPolicy) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionPolicySpecialtyLengthRule: SubstitutionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionPolicy) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionPolicyExternalRefLengthRule: SubstitutionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionPolicy) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionPolicyCodeLengthRule: SubstitutionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution policy.
    final class SubstitutionPolicyValidator {
        var rules: [any SubstitutionPolicyRule]

        init(rules: [any SubstitutionPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionPolicy) -> [String] {
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

        func requireValid(_ item: SubstitutionPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionPolicy]) -> [String: [String]] {
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

    static func defaultSubstitutionPolicyValidator() -> SubstitutionPolicyValidator {
        return SubstitutionPolicyValidator(
            rules: [
                SubstitutionPolicyRequiredSpecialtyRule(message: "substitution policy needs an entry"),
                SubstitutionPolicySpecialtyLengthRule(maxLength: 16),
                SubstitutionPolicyExternalRefLengthRule(maxLength: 80),
                SubstitutionPolicyCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
