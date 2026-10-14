import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal summary must pass. Check returns its problems, or none.
    protocol GoalSummaryRule {
        func check(_ item: GoalSummary) -> [String]
    }

    final class GoalSummaryRequiredTitleRule: GoalSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalSummaryCodeLengthRule: GoalSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalSummaryCountryLengthRule: GoalSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalSummary) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal summary.
    final class GoalSummaryValidator {
        var rules: [any GoalSummaryRule]

        init(rules: [any GoalSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalSummary]) -> [String: [String]] {
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

    static func defaultGoalSummaryValidator() -> GoalSummaryValidator {
        return GoalSummaryValidator(
            rules: [
                GoalSummaryRequiredTitleRule(message: "goal summary needs an entry"),
                GoalSummaryCodeLengthRule(maxLength: 80),
                GoalSummaryCountryLengthRule(maxLength: 3600),
            ]
        )
    }
}
