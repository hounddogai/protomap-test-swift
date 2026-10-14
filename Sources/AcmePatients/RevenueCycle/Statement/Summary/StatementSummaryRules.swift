import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement summary must pass. Check returns its problems, or none.
    protocol StatementSummaryRule {
        func check(_ item: StatementSummary) -> [String]
    }

    final class StatementSummaryRequiredCodeRule: StatementSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementSummaryRequiredTimezoneRule: StatementSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementSummary) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementSummaryTimezoneLengthRule: StatementSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSummary) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementSummaryBudgetRangeRule: StatementSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSummary) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementSummaryApprovedGuardRule: StatementSummaryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StatementSummary) -> [String] {
            if item.approved && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a statement summary.
    final class StatementSummaryValidator {
        var rules: [any StatementSummaryRule]

        init(rules: [any StatementSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementSummary) -> [String] {
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

        func requireValid(_ item: StatementSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementSummary]) -> [String: [String]] {
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

    static func defaultStatementSummaryValidator() -> StatementSummaryValidator {
        return StatementSummaryValidator(
            rules: [
                StatementSummaryRequiredCodeRule(message: "statement summary needs an entry"),
                StatementSummaryRequiredTimezoneRule(message: "statement summary needs a value"),
                StatementSummaryTimezoneLengthRule(maxLength: 80),
                StatementSummaryBudgetRangeRule(min: 0.1, max: 997.7),
                StatementSummaryApprovedGuardRule(limit: 255),
            ]
        )
    }
}
