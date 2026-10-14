import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled alert rollup must pass. Check returns its problems, or none.
    protocol ScheduledAlertRollupRule {
        func check(_ item: ScheduledAlertRollup) -> [String]
    }

    final class ScheduledAlertRollupRequiredCodeRule: ScheduledAlertRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertRollupWardLengthRule: ScheduledAlertRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertRollup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAlertRollupLabelLengthRule: ScheduledAlertRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAlertRollupCodeLengthRule: ScheduledAlertRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled alert rollup.
    final class ScheduledAlertRollupValidator {
        var rules: [any ScheduledAlertRollupRule]

        init(rules: [any ScheduledAlertRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAlertRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAlertRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAlertRollup]) -> [String: [String]] {
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

    static func defaultScheduledAlertRollupValidator() -> ScheduledAlertRollupValidator {
        return ScheduledAlertRollupValidator(
            rules: [
                ScheduledAlertRollupRequiredCodeRule(message: "scheduled alert rollup needs this field"),
                ScheduledAlertRollupWardLengthRule(maxLength: 86400),
                ScheduledAlertRollupLabelLengthRule(maxLength: 86400),
                ScheduledAlertRollupCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
