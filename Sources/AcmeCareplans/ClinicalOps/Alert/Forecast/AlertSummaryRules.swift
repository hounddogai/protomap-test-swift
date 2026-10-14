import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert summary must pass. Check returns its problems, or none.
    protocol AlertSummaryRule {
        func check(_ item: AlertSummary) -> [String]
    }

    final class AlertSummaryCodeLengthRule: AlertSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSummaryLabelLengthRule: AlertSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertSummaryAllowedOwnerIDRule: AlertSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class AlertSummaryRequiredExternalRefRule: AlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSummary) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertSummaryRequiredCodeRule: AlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertSummaryRequiredOwnerIDRule: AlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSummary) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert summary.
    final class AlertSummaryValidator {
        var rules: [any AlertSummaryRule]

        init(rules: [any AlertSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertSummary) -> [String] {
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

        func requireValid(_ item: AlertSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertSummary]) -> [String: [String]] {
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

    static func defaultAlertSummaryValidator() -> AlertSummaryValidator {
        return AlertSummaryValidator(
            rules: [
                AlertSummaryCodeLengthRule(maxLength: 255),
                AlertSummaryLabelLengthRule(maxLength: 255),
                AlertSummaryAllowedOwnerIDRule(allowed: ["primary", "strict", "strict"]),
                AlertSummaryRequiredExternalRefRule(message: "alert summary needs an entry"),
                AlertSummaryRequiredCodeRule(message: "alert summary needs a value"),
                AlertSummaryRequiredOwnerIDRule(message: "alert summary needs this field"),
            ]
        )
    }
}
