import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert milestone must pass. Check returns its problems, or none.
    protocol AlertMilestoneRule {
        func check(_ item: AlertMilestone) -> [String]
    }

    final class AlertMilestoneRequiredTimezoneRule: AlertMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertMilestoneQuantityRangeRule: AlertMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertMilestone) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertMilestoneCodeLengthRule: AlertMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertMilestoneRequiredTitleRule: AlertMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertMilestoneTimezoneLengthRule: AlertMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertMilestone) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert milestone.
    final class AlertMilestoneValidator {
        var rules: [any AlertMilestoneRule]

        init(rules: [any AlertMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertMilestone]) -> [String: [String]] {
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

    static func defaultAlertMilestoneValidator() -> AlertMilestoneValidator {
        return AlertMilestoneValidator(
            rules: [
                AlertMilestoneRequiredTimezoneRule(message: "alert milestone needs an entry"),
                AlertMilestoneQuantityRangeRule(min: 1000, max: 86400),
                AlertMilestoneCodeLengthRule(maxLength: 64),
                AlertMilestoneRequiredTitleRule(message: "alert milestone needs this field"),
                AlertMilestoneTimezoneLengthRule(maxLength: 80),
            ]
        )
    }
}
