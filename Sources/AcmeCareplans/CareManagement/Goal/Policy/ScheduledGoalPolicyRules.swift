import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled goal policy must pass. Check returns its problems, or none.
    protocol ScheduledGoalPolicyRule {
        func check(_ item: ScheduledGoalPolicy) -> [String]
    }

    final class ScheduledGoalPolicyPhoneLengthRule: ScheduledGoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalPolicy) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalPolicyRequiredLocaleRule: ScheduledGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalPolicy) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalPolicyCodeLengthRule: ScheduledGoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalPolicyRequiredCodeRule: ScheduledGoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalPolicyCodePrefixRule: ScheduledGoalPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledGoalPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled goal policy.
    final class ScheduledGoalPolicyValidator {
        var rules: [any ScheduledGoalPolicyRule]

        init(rules: [any ScheduledGoalPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledGoalPolicy) -> [String] {
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

        func requireValid(_ item: ScheduledGoalPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledGoalPolicy]) -> [String: [String]] {
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

    static func defaultScheduledGoalPolicyValidator() -> ScheduledGoalPolicyValidator {
        return ScheduledGoalPolicyValidator(
            rules: [
                ScheduledGoalPolicyPhoneLengthRule(maxLength: 64),
                ScheduledGoalPolicyRequiredLocaleRule(message: "scheduled goal policy needs a value"),
                ScheduledGoalPolicyCodeLengthRule(maxLength: 86400),
                ScheduledGoalPolicyRequiredCodeRule(message: "scheduled goal policy needs an entry"),
                ScheduledGoalPolicyCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
