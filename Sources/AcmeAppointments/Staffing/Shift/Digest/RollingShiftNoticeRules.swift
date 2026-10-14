import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling shift notice must pass. Check returns its problems, or none.
    protocol RollingShiftNoticeRule {
        func check(_ item: RollingShiftNotice) -> [String]
    }

    final class RollingShiftNoticeRequiredLabelRule: RollingShiftNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingShiftNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingShiftNoticeAllowedSummaryRule: RollingShiftNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingShiftNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is blocked"]
            }
            return []
        }
    }

    final class RollingShiftNoticeCodePrefixRule: RollingShiftNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingShiftNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingShiftNoticeRequiredReviewerRule: RollingShiftNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingShiftNotice) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingShiftNoticeCodeLengthRule: RollingShiftNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingShiftNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling shift notice.
    final class RollingShiftNoticeValidator {
        var rules: [any RollingShiftNoticeRule]

        init(rules: [any RollingShiftNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingShiftNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingShiftNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingShiftNotice]) -> [String: [String]] {
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

    static func defaultRollingShiftNoticeValidator() -> RollingShiftNoticeValidator {
        return RollingShiftNoticeValidator(
            rules: [
                RollingShiftNoticeRequiredLabelRule(message: "rolling shift notice needs a value"),
                RollingShiftNoticeAllowedSummaryRule(allowed: ["regional"]),
                RollingShiftNoticeCodePrefixRule(prefix: "X"),
                RollingShiftNoticeRequiredReviewerRule(message: "rolling shift notice needs an entry"),
                RollingShiftNoticeCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
