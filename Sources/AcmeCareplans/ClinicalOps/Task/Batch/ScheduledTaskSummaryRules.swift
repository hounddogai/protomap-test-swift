import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled task summary must pass. Check returns its problems, or none.
    protocol ScheduledTaskSummaryRule {
        func check(_ item: ScheduledTaskSummary) -> [String]
    }

    final class ScheduledTaskSummaryCodePrefixRule: ScheduledTaskSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledTaskSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledTaskSummaryRequiredLabelRule: ScheduledTaskSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTaskSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledTaskSummaryLabelLengthRule: ScheduledTaskSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskSummaryBedLengthRule: ScheduledTaskSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskSummary) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskSummaryRequiredBedRule: ScheduledTaskSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTaskSummary) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled task summary.
    final class ScheduledTaskSummaryValidator {
        var rules: [any ScheduledTaskSummaryRule]

        init(rules: [any ScheduledTaskSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledTaskSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledTaskSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledTaskSummary]) -> [String: [String]] {
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

    static func defaultScheduledTaskSummaryValidator() -> ScheduledTaskSummaryValidator {
        return ScheduledTaskSummaryValidator(
            rules: [
                ScheduledTaskSummaryCodePrefixRule(prefix: "X"),
                ScheduledTaskSummaryRequiredLabelRule(message: "scheduled task summary needs this field"),
                ScheduledTaskSummaryLabelLengthRule(maxLength: 16),
                ScheduledTaskSummaryBedLengthRule(maxLength: 86400),
                ScheduledTaskSummaryRequiredBedRule(message: "scheduled task summary needs an entry"),
            ]
        )
    }
}
