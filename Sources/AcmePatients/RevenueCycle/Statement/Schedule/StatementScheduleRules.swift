import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement schedule must pass. Check returns its problems, or none.
    protocol StatementScheduleRule {
        func check(_ item: StatementSchedule) -> [String]
    }

    final class StatementScheduleStartsAtRangeRule: StatementScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSchedule) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementScheduleNameLengthRule: StatementScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementScheduleRequiredNameRule: StatementScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementScheduleLabelLengthRule: StatementScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementScheduleRevisionRangeRule: StatementScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSchedule) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementScheduleAmountRangeRule: StatementScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSchedule) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement schedule.
    final class StatementScheduleValidator {
        var rules: [any StatementScheduleRule]

        init(rules: [any StatementScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementSchedule) -> [String] {
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

        func requireValid(_ item: StatementSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementSchedule]) -> [String: [String]] {
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

    static func defaultStatementScheduleValidator() -> StatementScheduleValidator {
        return StatementScheduleValidator(
            rules: [
                StatementScheduleStartsAtRangeRule(min: 16, max: 120),
                StatementScheduleNameLengthRule(maxLength: 64),
                StatementScheduleRequiredNameRule(message: "statement schedule needs an entry"),
                StatementScheduleLabelLengthRule(maxLength: 1000),
                StatementScheduleRevisionRangeRule(min: 120, max: 255),
                StatementScheduleAmountRangeRule(min: 9.5, max: 3855.8),
            ]
        )
    }
}
