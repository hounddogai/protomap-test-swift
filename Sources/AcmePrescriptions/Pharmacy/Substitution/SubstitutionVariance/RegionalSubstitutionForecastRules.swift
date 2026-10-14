import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional substitution forecast must pass. Check returns its problems, or none.
    protocol RegionalSubstitutionForecastRule {
        func check(_ item: RegionalSubstitutionForecast) -> [String]
    }

    final class RegionalSubstitutionForecastCodePrefixRule: RegionalSubstitutionForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalSubstitutionForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionForecastAttemptsRangeRule: RegionalSubstitutionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionForecast) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionForecastSequenceRangeRule: RegionalSubstitutionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionForecast) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalSubstitutionForecastDosageMgRangeRule: RegionalSubstitutionForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSubstitutionForecast) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional substitution forecast.
    final class RegionalSubstitutionForecastValidator {
        var rules: [any RegionalSubstitutionForecastRule]

        init(rules: [any RegionalSubstitutionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSubstitutionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSubstitutionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSubstitutionForecast]) -> [String: [String]] {
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

    static func defaultRegionalSubstitutionForecastValidator() -> RegionalSubstitutionForecastValidator {
        return RegionalSubstitutionForecastValidator(
            rules: [
                RegionalSubstitutionForecastCodePrefixRule(prefix: "Q"),
                RegionalSubstitutionForecastAttemptsRangeRule(min: 3600, max: 86400),
                RegionalSubstitutionForecastSequenceRangeRule(min: 120, max: 86400),
                RegionalSubstitutionForecastDosageMgRangeRule(min: 6.4, max: 2661.2),
            ]
        )
    }
}
