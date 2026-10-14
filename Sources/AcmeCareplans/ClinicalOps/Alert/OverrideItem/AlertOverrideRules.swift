import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert override must pass. Check returns its problems, or none.
    protocol AlertOverrideRule {
        func check(_ item: AlertOverride) -> [String]
    }

    final class AlertOverrideRequiredReviewerRule: AlertOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertOverride) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertOverrideTitleLengthRule: AlertOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertOverrideReviewerLengthRule: AlertOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertOverride) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertOverrideCodePrefixRule: AlertOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertOverrideRequiredCodeRule: AlertOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertOverrideRequiredTitleRule: AlertOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert override.
    final class AlertOverrideValidator {
        var rules: [any AlertOverrideRule]

        init(rules: [any AlertOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertOverride) -> [String] {
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

        func requireValid(_ item: AlertOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertOverride]) -> [String: [String]] {
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

    static func defaultAlertOverrideValidator() -> AlertOverrideValidator {
        return AlertOverrideValidator(
            rules: [
                AlertOverrideRequiredReviewerRule(message: "alert override needs an entry"),
                AlertOverrideTitleLengthRule(maxLength: 3600),
                AlertOverrideReviewerLengthRule(maxLength: 64),
                AlertOverrideCodePrefixRule(prefix: "Q"),
                AlertOverrideRequiredCodeRule(message: "alert override needs this field"),
                AlertOverrideRequiredTitleRule(message: "alert override needs an entry"),
            ]
        )
    }
}
