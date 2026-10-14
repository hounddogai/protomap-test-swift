import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix forecast must pass. Check returns its problems, or none.
    protocol SkillMixForecastRule {
        func check(_ item: SkillMixForecast) -> [String]
    }

    final class SkillMixForecastCeilingRangeRule: SkillMixForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixForecast) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixForecastRequiredTitleRule: SkillMixForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixForecastRequiredCodeRule: SkillMixForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix forecast.
    final class SkillMixForecastValidator {
        var rules: [any SkillMixForecastRule]

        init(rules: [any SkillMixForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixForecast) -> [String] {
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

        func requireValid(_ item: SkillMixForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixForecast]) -> [String: [String]] {
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

    static func defaultSkillMixForecastValidator() -> SkillMixForecastValidator {
        return SkillMixForecastValidator(
            rules: [
                SkillMixForecastCeilingRangeRule(min: 0.0, max: 104.3),
                SkillMixForecastRequiredTitleRule(message: "skill mix forecast needs a value"),
                SkillMixForecastRequiredCodeRule(message: "skill mix forecast needs this field"),
            ]
        )
    }
}
