import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled outreach request must pass. Check returns its problems, or none.
    protocol ScheduledOutreachRequestRule {
        func check(_ item: ScheduledOutreachRequest) -> [String]
    }

    final class ScheduledOutreachRequestRequiredNameRule: ScheduledOutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOutreachRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOutreachRequestRequiredTimezoneRule: ScheduledOutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOutreachRequest) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOutreachRequestRequiredCodeRule: ScheduledOutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOutreachRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOutreachRequestCodePrefixRule: ScheduledOutreachRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledOutreachRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledOutreachRequestTimezoneLengthRule: ScheduledOutreachRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOutreachRequest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled outreach request.
    final class ScheduledOutreachRequestValidator {
        var rules: [any ScheduledOutreachRequestRule]

        init(rules: [any ScheduledOutreachRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOutreachRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledOutreachRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOutreachRequest]) -> [String: [String]] {
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

    static func defaultScheduledOutreachRequestValidator() -> ScheduledOutreachRequestValidator {
        return ScheduledOutreachRequestValidator(
            rules: [
                ScheduledOutreachRequestRequiredNameRule(message: "scheduled outreach request needs a value"),
                ScheduledOutreachRequestRequiredTimezoneRule(message: "scheduled outreach request needs an entry"),
                ScheduledOutreachRequestRequiredCodeRule(message: "scheduled outreach request needs an entry"),
                ScheduledOutreachRequestCodePrefixRule(prefix: "X"),
                ScheduledOutreachRequestTimezoneLengthRule(maxLength: 32),
            ]
        )
    }
}
