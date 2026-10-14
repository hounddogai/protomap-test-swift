import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled statement notice must pass. Check returns its problems, or none.
    protocol ScheduledStatementNoticeRule {
        func check(_ item: ScheduledStatementNotice) -> [String]
    }

    final class ScheduledStatementNoticeCodePrefixRule: ScheduledStatementNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledStatementNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledStatementNoticeAllowedTimezoneRule: ScheduledStatementNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledStatementNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is duplicated"]
            }
            return []
        }
    }

    final class ScheduledStatementNoticeContactEmailLengthRule: ScheduledStatementNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledStatementNotice) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled statement notice.
    final class ScheduledStatementNoticeValidator {
        var rules: [any ScheduledStatementNoticeRule]

        init(rules: [any ScheduledStatementNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledStatementNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledStatementNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledStatementNotice]) -> [String: [String]] {
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

    static func defaultScheduledStatementNoticeValidator() -> ScheduledStatementNoticeValidator {
        return ScheduledStatementNoticeValidator(
            rules: [
                ScheduledStatementNoticeCodePrefixRule(prefix: "ACM"),
                ScheduledStatementNoticeAllowedTimezoneRule(allowed: ["pending", "capped"]),
                ScheduledStatementNoticeContactEmailLengthRule(maxLength: 64),
            ]
        )
    }
}
