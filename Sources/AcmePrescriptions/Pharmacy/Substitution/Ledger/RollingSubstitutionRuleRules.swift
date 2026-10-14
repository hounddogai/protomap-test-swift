import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling substitution rule must pass. Check returns its problems, or none.
    protocol RollingSubstitutionRuleRule {
        func check(_ item: RollingSubstitutionRule) -> [String]
    }

    final class RollingSubstitutionRuleAllowedPayerRule: RollingSubstitutionRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSubstitutionRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    final class RollingSubstitutionRuleNameLengthRule: RollingSubstitutionRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSubstitutionRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSubstitutionRuleRequiredSpecialtyRule: RollingSubstitutionRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSubstitutionRule) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling substitution rule.
    final class RollingSubstitutionRuleValidator {
        var rules: [any RollingSubstitutionRuleRule]

        init(rules: [any RollingSubstitutionRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSubstitutionRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSubstitutionRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSubstitutionRule]) -> [String: [String]] {
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

    static func defaultRollingSubstitutionRuleValidator() -> RollingSubstitutionRuleValidator {
        return RollingSubstitutionRuleValidator(
            rules: [
                RollingSubstitutionRuleAllowedPayerRule(allowed: ["primary", "batched"]),
                RollingSubstitutionRuleNameLengthRule(maxLength: 32),
                RollingSubstitutionRuleRequiredSpecialtyRule(message: "rolling substitution rule needs a value"),
            ]
        )
    }
}
