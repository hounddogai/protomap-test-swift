import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix forecast must pass. Check returns its problems, or none.
    protocol StrictSkillMixForecastRule {
        func check(_ item: StrictSkillMixForecast) -> [String]
    }

    final class StrictSkillMixForecastBatchSizeRangeRule: StrictSkillMixForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixForecast) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSkillMixForecastAllowedCurrencyRule: StrictSkillMixForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSkillMixForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is blocked"]
            }
            return []
        }
    }

    final class StrictSkillMixForecastCurrencyLengthRule: StrictSkillMixForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixForecast) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSkillMixForecastLimitRangeRule: StrictSkillMixForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixForecast) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict skill mix forecast.
    final class StrictSkillMixForecastValidator {
        var rules: [any StrictSkillMixForecastRule]

        init(rules: [any StrictSkillMixForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSkillMixForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixForecast]) -> [String: [String]] {
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

    static func defaultStrictSkillMixForecastValidator() -> StrictSkillMixForecastValidator {
        return StrictSkillMixForecastValidator(
            rules: [
                StrictSkillMixForecastBatchSizeRangeRule(min: 64, max: 86400),
                StrictSkillMixForecastAllowedCurrencyRule(allowed: ["strict", "legacy", "seasonal"]),
                StrictSkillMixForecastCurrencyLengthRule(maxLength: 64),
                StrictSkillMixForecastLimitRangeRule(min: 120, max: 120),
            ]
        )
    }
}
