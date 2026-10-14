import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up policy must pass. Check returns its problems, or none.
    protocol FollowUpPolicyRule {
        func check(_ item: FollowUpPolicy) -> [String]
    }

    final class FollowUpPolicyCodeLengthRule: FollowUpPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPolicyRequiredLabelRule: FollowUpPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpPolicyRequiredCodeRule: FollowUpPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up policy.
    final class FollowUpPolicyValidator {
        var rules: [any FollowUpPolicyRule]

        init(rules: [any FollowUpPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpPolicy]) -> [String: [String]] {
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

    static func defaultFollowUpPolicyValidator() -> FollowUpPolicyValidator {
        return FollowUpPolicyValidator(
            rules: [
                FollowUpPolicyCodeLengthRule(maxLength: 255),
                FollowUpPolicyRequiredLabelRule(message: "follow up policy needs this field"),
                FollowUpPolicyRequiredCodeRule(message: "follow up policy needs this field"),
            ]
        )
    }
}
