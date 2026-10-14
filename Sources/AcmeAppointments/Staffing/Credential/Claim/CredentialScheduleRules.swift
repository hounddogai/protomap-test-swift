import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential schedule must pass. Check returns its problems, or none.
    protocol CredentialScheduleRule {
        func check(_ item: CredentialSchedule) -> [String]
    }

    final class CredentialScheduleRequiredCurrencyRule: CredentialScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialSchedule) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialScheduleReviewerLengthRule: CredentialScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialSchedule) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialScheduleRetriesRangeRule: CredentialScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialSchedule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialScheduleCodePrefixRule: CredentialScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialScheduleRequiredReviewerRule: CredentialScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialSchedule) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential schedule.
    final class CredentialScheduleValidator {
        var rules: [any CredentialScheduleRule]

        init(rules: [any CredentialScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialSchedule]) -> [String: [String]] {
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

    static func defaultCredentialScheduleValidator() -> CredentialScheduleValidator {
        return CredentialScheduleValidator(
            rules: [
                CredentialScheduleRequiredCurrencyRule(message: "credential schedule needs a value"),
                CredentialScheduleReviewerLengthRule(maxLength: 86400),
                CredentialScheduleRetriesRangeRule(min: 64, max: 86400),
                CredentialScheduleCodePrefixRule(prefix: "ACM"),
                CredentialScheduleRequiredReviewerRule(message: "credential schedule needs an entry"),
            ]
        )
    }
}
