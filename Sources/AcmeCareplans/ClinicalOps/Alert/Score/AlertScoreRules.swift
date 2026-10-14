import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert score must pass. Check returns its problems, or none.
    protocol AlertScoreRule {
        func check(_ item: AlertScore) -> [String]
    }

    final class AlertScoreBudgetRangeRule: AlertScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertScore) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertScoreRequiredCategoryRule: AlertScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertScore) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertScoreCountryLengthRule: AlertScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertScore) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertScoreCategoryLengthRule: AlertScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertScore) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertScoreRequiredCountryRule: AlertScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertScore) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert score.
    final class AlertScoreValidator {
        var rules: [any AlertScoreRule]

        init(rules: [any AlertScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertScore]) -> [String: [String]] {
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

    static func defaultAlertScoreValidator() -> AlertScoreValidator {
        return AlertScoreValidator(
            rules: [
                AlertScoreBudgetRangeRule(min: 3.7, max: 1615.0),
                AlertScoreRequiredCategoryRule(message: "alert score needs an entry"),
                AlertScoreCountryLengthRule(maxLength: 3600),
                AlertScoreCategoryLengthRule(maxLength: 3600),
                AlertScoreRequiredCountryRule(message: "alert score needs an entry"),
            ]
        )
    }
}
