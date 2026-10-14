import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy cleaning forecast must pass. Check returns its problems, or none.
    protocol LegacyCleaningForecastRule {
        func check(_ item: LegacyCleaningForecast) -> [String]
    }

    final class LegacyCleaningForecastRequiredTitleRule: LegacyCleaningForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCleaningForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCleaningForecastRevisionRangeRule: LegacyCleaningForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCleaningForecast) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCleaningForecastPriorityRangeRule: LegacyCleaningForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCleaningForecast) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCleaningForecastCreatedAtRangeRule: LegacyCleaningForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCleaningForecast) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy cleaning forecast.
    final class LegacyCleaningForecastValidator {
        var rules: [any LegacyCleaningForecastRule]

        init(rules: [any LegacyCleaningForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCleaningForecast) -> [String] {
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

        func requireValid(_ item: LegacyCleaningForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCleaningForecast]) -> [String: [String]] {
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

    static func defaultLegacyCleaningForecastValidator() -> LegacyCleaningForecastValidator {
        return LegacyCleaningForecastValidator(
            rules: [
                LegacyCleaningForecastRequiredTitleRule(message: "legacy cleaning forecast needs an entry"),
                LegacyCleaningForecastRevisionRangeRule(min: 120, max: 1000),
                LegacyCleaningForecastPriorityRangeRule(min: 3600, max: 3600),
                LegacyCleaningForecastCreatedAtRangeRule(min: 64, max: 120),
            ]
        )
    }
}
