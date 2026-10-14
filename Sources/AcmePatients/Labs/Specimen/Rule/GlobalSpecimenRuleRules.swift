import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global specimen rule must pass. Check returns its problems, or none.
    protocol GlobalSpecimenRuleRule {
        func check(_ item: GlobalSpecimenRule) -> [String]
    }

    final class GlobalSpecimenRuleAllergyLengthRule: GlobalSpecimenRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenRule) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSpecimenRuleRequiredTitleRule: GlobalSpecimenRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenRuleAllowedCodeRule: GlobalSpecimenRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSpecimenRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a global specimen rule.
    final class GlobalSpecimenRuleValidator {
        var rules: [any GlobalSpecimenRuleRule]

        init(rules: [any GlobalSpecimenRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSpecimenRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSpecimenRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSpecimenRule]) -> [String: [String]] {
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

    static func defaultGlobalSpecimenRuleValidator() -> GlobalSpecimenRuleValidator {
        return GlobalSpecimenRuleValidator(
            rules: [
                GlobalSpecimenRuleAllergyLengthRule(maxLength: 80),
                GlobalSpecimenRuleRequiredTitleRule(message: "global specimen rule needs a value"),
                GlobalSpecimenRuleAllowedCodeRule(allowed: ["primary", "seasonal"]),
            ]
        )
    }
}
