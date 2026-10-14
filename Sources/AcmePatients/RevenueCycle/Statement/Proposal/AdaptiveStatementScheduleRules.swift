import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive statement schedule must pass. Check returns its problems, or none.
    protocol AdaptiveStatementScheduleRule {
        func check(_ item: AdaptiveStatementSchedule) -> [String]
    }

    final class AdaptiveStatementScheduleRequiredSummaryRule: AdaptiveStatementScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveStatementSchedule) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveStatementScheduleAllowedSummaryRule: AdaptiveStatementScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveStatementSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is duplicated"]
            }
            return []
        }
    }

    final class AdaptiveStatementScheduleCodePrefixRule: AdaptiveStatementScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveStatementSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveStatementScheduleCodeLengthRule: AdaptiveStatementScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveStatementScheduleSummaryLengthRule: AdaptiveStatementScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveStatementSchedule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive statement schedule.
    final class AdaptiveStatementScheduleValidator {
        var rules: [any AdaptiveStatementScheduleRule]

        init(rules: [any AdaptiveStatementScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveStatementSchedule) -> [String] {
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

        func requireValid(_ item: AdaptiveStatementSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveStatementSchedule]) -> [String: [String]] {
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

    static func defaultAdaptiveStatementScheduleValidator() -> AdaptiveStatementScheduleValidator {
        return AdaptiveStatementScheduleValidator(
            rules: [
                AdaptiveStatementScheduleRequiredSummaryRule(message: "adaptive statement schedule needs this field"),
                AdaptiveStatementScheduleAllowedSummaryRule(allowed: []),
                AdaptiveStatementScheduleCodePrefixRule(prefix: "ACM"),
                AdaptiveStatementScheduleCodeLengthRule(maxLength: 16),
                AdaptiveStatementScheduleSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
