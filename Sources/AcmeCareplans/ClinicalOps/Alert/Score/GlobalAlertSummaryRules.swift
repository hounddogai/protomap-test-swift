import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global alert summary must pass. Check returns its problems, or none.
    protocol GlobalAlertSummaryRule {
        func check(_ item: GlobalAlertSummary) -> [String]
    }

    final class GlobalAlertSummaryAllowedNameRule: GlobalAlertSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAlertSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class GlobalAlertSummaryCodePrefixRule: GlobalAlertSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalAlertSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalAlertSummaryRequiredDescriptionRule: GlobalAlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertSummary) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertSummaryDescriptionLengthRule: GlobalAlertSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAlertSummary) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAlertSummaryRequiredNameRule: GlobalAlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global alert summary.
    final class GlobalAlertSummaryValidator {
        var rules: [any GlobalAlertSummaryRule]

        init(rules: [any GlobalAlertSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAlertSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAlertSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAlertSummary]) -> [String: [String]] {
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

    static func defaultGlobalAlertSummaryValidator() -> GlobalAlertSummaryValidator {
        return GlobalAlertSummaryValidator(
            rules: [
                GlobalAlertSummaryAllowedNameRule(allowed: []),
                GlobalAlertSummaryCodePrefixRule(prefix: "REF"),
                GlobalAlertSummaryRequiredDescriptionRule(message: "global alert summary needs this field"),
                GlobalAlertSummaryDescriptionLengthRule(maxLength: 16),
                GlobalAlertSummaryRequiredNameRule(message: "global alert summary needs a value"),
            ]
        )
    }
}
