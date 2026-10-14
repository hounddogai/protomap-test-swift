import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled alert summary must pass. Check returns its problems, or none.
    protocol ScheduledAlertSummaryRule {
        func check(_ item: ScheduledAlertSummary) -> [String]
    }

    final class ScheduledAlertSummaryRequiredLocaleRule: ScheduledAlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertSummaryRequiredLabelRule: ScheduledAlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertSummaryRequiredCodeRule: ScheduledAlertSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertSummaryLabelLengthRule: ScheduledAlertSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAlertSummaryLocaleLengthRule: ScheduledAlertSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAlertSummaryAmountRangeRule: ScheduledAlertSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAlertSummary) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled alert summary.
    final class ScheduledAlertSummaryValidator {
        var rules: [any ScheduledAlertSummaryRule]

        init(rules: [any ScheduledAlertSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAlertSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAlertSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAlertSummary]) -> [String: [String]] {
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

    static func defaultScheduledAlertSummaryValidator() -> ScheduledAlertSummaryValidator {
        return ScheduledAlertSummaryValidator(
            rules: [
                ScheduledAlertSummaryRequiredLocaleRule(message: "scheduled alert summary needs an entry"),
                ScheduledAlertSummaryRequiredLabelRule(message: "scheduled alert summary needs this field"),
                ScheduledAlertSummaryRequiredCodeRule(message: "scheduled alert summary needs this field"),
                ScheduledAlertSummaryLabelLengthRule(maxLength: 120),
                ScheduledAlertSummaryLocaleLengthRule(maxLength: 3600),
                ScheduledAlertSummaryAmountRangeRule(min: 6.2, max: 4443.5),
            ]
        )
    }
}
