import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal agreement must pass. Check returns its problems, or none.
    protocol GoalAgreementRule {
        func check(_ item: GoalAgreement) -> [String]
    }

    final class GoalAgreementRequiredCodeRule: GoalAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAgreementRequiredNameRule: GoalAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAgreementCodePrefixRule: GoalAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalAgreementCodeLengthRule: GoalAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal agreement.
    final class GoalAgreementValidator {
        var rules: [any GoalAgreementRule]

        init(rules: [any GoalAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalAgreement]) -> [String: [String]] {
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

    static func defaultGoalAgreementValidator() -> GoalAgreementValidator {
        return GoalAgreementValidator(
            rules: [
                GoalAgreementRequiredCodeRule(message: "goal agreement needs an entry"),
                GoalAgreementRequiredNameRule(message: "goal agreement needs a value"),
                GoalAgreementCodePrefixRule(prefix: "X"),
                GoalAgreementCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
