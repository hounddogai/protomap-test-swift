import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation rule must pass. Check returns its problems, or none.
    protocol RevocationRuleRule {
        func check(_ item: RevocationRule) -> [String]
    }

    final class RevocationRuleRequiredAllergyRule: RevocationRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationRule) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationRuleNameLengthRule: RevocationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationRuleRequiredNameRule: RevocationRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationRuleAllergyLengthRule: RevocationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationRule) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation rule.
    final class RevocationRuleValidator {
        var rules: [any RevocationRuleRule]

        init(rules: [any RevocationRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationRule) -> [String] {
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

        func requireValid(_ item: RevocationRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationRule]) -> [String: [String]] {
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

    static func defaultRevocationRuleValidator() -> RevocationRuleValidator {
        return RevocationRuleValidator(
            rules: [
                RevocationRuleRequiredAllergyRule(message: "revocation rule needs an entry"),
                RevocationRuleNameLengthRule(maxLength: 80),
                RevocationRuleRequiredNameRule(message: "revocation rule needs a value"),
                RevocationRuleAllergyLengthRule(maxLength: 86400),
            ]
        )
    }
}
