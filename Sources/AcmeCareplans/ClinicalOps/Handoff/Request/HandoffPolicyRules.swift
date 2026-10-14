import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff policy must pass. Check returns its problems, or none.
    protocol HandoffPolicyRule {
        func check(_ item: HandoffPolicy) -> [String]
    }

    final class HandoffPolicyProcedureCodeLengthRule: HandoffPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffPolicy) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffPolicyRequiredLabelRule: HandoffPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffPolicyAllowedSourceRule: HandoffPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is above maximum"]
            }
            return []
        }
    }

    final class HandoffPolicyTitleLengthRule: HandoffPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff policy.
    final class HandoffPolicyValidator {
        var rules: [any HandoffPolicyRule]

        init(rules: [any HandoffPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffPolicy]) -> [String: [String]] {
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

    static func defaultHandoffPolicyValidator() -> HandoffPolicyValidator {
        return HandoffPolicyValidator(
            rules: [
                HandoffPolicyProcedureCodeLengthRule(maxLength: 32),
                HandoffPolicyRequiredLabelRule(message: "handoff policy needs an entry"),
                HandoffPolicyAllowedSourceRule(allowed: []),
                HandoffPolicyTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
