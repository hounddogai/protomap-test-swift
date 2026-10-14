import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding forecast must pass. Check returns its problems, or none.
    protocol RoundingForecastRule {
        func check(_ item: RoundingForecast) -> [String]
    }

    final class RoundingForecastCodeLengthRule: RoundingForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingForecastEndsAtRangeRule: RoundingForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingForecast) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingForecastLimitRangeRule: RoundingForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingForecast) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingForecastAllowedCodeRule: RoundingForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding forecast.
    final class RoundingForecastValidator {
        var rules: [any RoundingForecastRule]

        init(rules: [any RoundingForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingForecast]) -> [String: [String]] {
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

    static func defaultRoundingForecastValidator() -> RoundingForecastValidator {
        return RoundingForecastValidator(
            rules: [
                RoundingForecastCodeLengthRule(maxLength: 32),
                RoundingForecastEndsAtRangeRule(min: 16, max: 120),
                RoundingForecastLimitRangeRule(min: 64, max: 1000),
                RoundingForecastAllowedCodeRule(allowed: ["capped", "batched", "pending"]),
            ]
        )
    }
}
