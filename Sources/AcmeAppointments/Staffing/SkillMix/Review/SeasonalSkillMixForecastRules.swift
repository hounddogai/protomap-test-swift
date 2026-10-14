import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix forecast must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixForecastRule {
        func check(_ item: SeasonalSkillMixForecast) -> [String]
    }

    final class SeasonalSkillMixForecastCodePrefixRule: SeasonalSkillMixForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixForecastProcedureCodeLengthRule: SeasonalSkillMixForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixForecastCodeLengthRule: SeasonalSkillMixForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixForecastRequiredProcedureCodeRule: SeasonalSkillMixForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixForecastRequiredCodeRule: SeasonalSkillMixForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixForecastRequiredNameRule: SeasonalSkillMixForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix forecast.
    final class SeasonalSkillMixForecastValidator {
        var rules: [any SeasonalSkillMixForecastRule]

        init(rules: [any SeasonalSkillMixForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixForecast) -> [String] {
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

        func requireValid(_ item: SeasonalSkillMixForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixForecast]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixForecastValidator() -> SeasonalSkillMixForecastValidator {
        return SeasonalSkillMixForecastValidator(
            rules: [
                SeasonalSkillMixForecastCodePrefixRule(prefix: "ACM"),
                SeasonalSkillMixForecastProcedureCodeLengthRule(maxLength: 1000),
                SeasonalSkillMixForecastCodeLengthRule(maxLength: 80),
                SeasonalSkillMixForecastRequiredProcedureCodeRule(
                    message: "seasonal skill mix forecast needs a value"
                ),
                SeasonalSkillMixForecastRequiredCodeRule(message: "seasonal skill mix forecast needs an entry"),
                SeasonalSkillMixForecastRequiredNameRule(message: "seasonal skill mix forecast needs this field"),
            ]
        )
    }
}
