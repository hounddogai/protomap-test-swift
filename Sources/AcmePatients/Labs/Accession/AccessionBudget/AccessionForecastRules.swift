import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession forecast must pass. Check returns its problems, or none.
    protocol AccessionForecastRule {
        func check(_ item: AccessionForecast) -> [String]
    }

    final class AccessionForecastCreatedAtRangeRule: AccessionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionForecast) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionForecastAllowedFacilityRule: AccessionForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is not allowed"]
            }
            return []
        }
    }

    final class AccessionForecastRequiredCodeRule: AccessionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionForecastCodeLengthRule: AccessionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionForecastRequiredTitleRule: AccessionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionForecastLocaleLengthRule: AccessionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionForecast) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession forecast.
    final class AccessionForecastValidator {
        var rules: [any AccessionForecastRule]

        init(rules: [any AccessionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionForecast]) -> [String: [String]] {
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

    static func defaultAccessionForecastValidator() -> AccessionForecastValidator {
        return AccessionForecastValidator(
            rules: [
                AccessionForecastCreatedAtRangeRule(min: 16, max: 120),
                AccessionForecastAllowedFacilityRule(allowed: ["pending"]),
                AccessionForecastRequiredCodeRule(message: "accession forecast needs this field"),
                AccessionForecastCodeLengthRule(maxLength: 120),
                AccessionForecastRequiredTitleRule(message: "accession forecast needs an entry"),
                AccessionForecastLocaleLengthRule(maxLength: 1000),
            ]
        )
    }
}
