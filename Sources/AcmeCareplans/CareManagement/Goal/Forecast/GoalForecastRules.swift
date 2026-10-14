import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal forecast must pass. Check returns its problems, or none.
    protocol GoalForecastRule {
        func check(_ item: GoalForecast) -> [String]
    }

    final class GoalForecastCodeLengthRule: GoalForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalForecastArchivedGuardRule: GoalForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GoalForecast) -> [String] {
            if item.archived && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GoalForecastTitleLengthRule: GoalForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalForecastRequiredTitleRule: GoalForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal forecast.
    final class GoalForecastValidator {
        var rules: [any GoalForecastRule]

        init(rules: [any GoalForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalForecast]) -> [String: [String]] {
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

    static func defaultGoalForecastValidator() -> GoalForecastValidator {
        return GoalForecastValidator(
            rules: [
                GoalForecastCodeLengthRule(maxLength: 16),
                GoalForecastArchivedGuardRule(limit: 3.2),
                GoalForecastTitleLengthRule(maxLength: 80),
                GoalForecastRequiredTitleRule(message: "goal forecast needs this field"),
            ]
        )
    }
}
