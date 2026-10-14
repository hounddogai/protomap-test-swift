import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled claim group must pass. Check returns its problems, or none.
    protocol ScheduledClaimGroupRule {
        func check(_ item: ScheduledClaimGroup) -> [String]
    }

    final class ScheduledClaimGroupContactEmailLengthRule: ScheduledClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClaimGroup) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledClaimGroupRequiredContactEmailRule: ScheduledClaimGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClaimGroup) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClaimGroupCodePrefixRule: ScheduledClaimGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledClaimGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledClaimGroupCodeLengthRule: ScheduledClaimGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClaimGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledClaimGroupRequiredPayerRule: ScheduledClaimGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClaimGroup) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled claim group.
    final class ScheduledClaimGroupValidator {
        var rules: [any ScheduledClaimGroupRule]

        init(rules: [any ScheduledClaimGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClaimGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledClaimGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClaimGroup]) -> [String: [String]] {
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

    static func defaultScheduledClaimGroupValidator() -> ScheduledClaimGroupValidator {
        return ScheduledClaimGroupValidator(
            rules: [
                ScheduledClaimGroupContactEmailLengthRule(maxLength: 1000),
                ScheduledClaimGroupRequiredContactEmailRule(message: "scheduled claim group needs a value"),
                ScheduledClaimGroupCodePrefixRule(prefix: "Q"),
                ScheduledClaimGroupCodeLengthRule(maxLength: 1000),
                ScheduledClaimGroupRequiredPayerRule(message: "scheduled claim group needs an entry"),
            ]
        )
    }
}
