import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall forecast must pass. Check returns its problems, or none.
    protocol RecallForecastRule {
        func check(_ item: RecallForecast) -> [String]
    }

    final class RecallForecastSequenceRangeRule: RecallForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallForecast) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallForecastAllowedReviewerRule: RecallForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is out of range"]
            }
            return []
        }
    }

    final class RecallForecastRequiredCodeRule: RecallForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallForecastTitleLengthRule: RecallForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallForecastCodeLengthRule: RecallForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallForecastStartsAtRangeRule: RecallForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallForecast) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall forecast.
    final class RecallForecastValidator {
        var rules: [any RecallForecastRule]

        init(rules: [any RecallForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallForecast]) -> [String: [String]] {
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

    static func defaultRecallForecastValidator() -> RecallForecastValidator {
        return RecallForecastValidator(
            rules: [
                RecallForecastSequenceRangeRule(min: 86400, max: 86400),
                RecallForecastAllowedReviewerRule(allowed: ["regional", "global"]),
                RecallForecastRequiredCodeRule(message: "recall forecast needs this field"),
                RecallForecastTitleLengthRule(maxLength: 64),
                RecallForecastCodeLengthRule(maxLength: 1000),
                RecallForecastStartsAtRangeRule(min: 120, max: 120),
            ]
        )
    }
}
