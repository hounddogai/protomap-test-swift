import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal formulary review must pass. Check returns its problems, or none.
    protocol SeasonalFormularyReviewRule {
        func check(_ item: SeasonalFormularyReview) -> [String]
    }

    final class SeasonalFormularyReviewBudgetRangeRule: SeasonalFormularyReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFormularyReview) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalFormularyReviewRequiredLabelRule: SeasonalFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFormularyReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFormularyReviewLabelLengthRule: SeasonalFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFormularyReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalFormularyReviewRequiredTitleRule: SeasonalFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFormularyReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFormularyReviewSequenceRangeRule: SeasonalFormularyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFormularyReview) -> [String] {
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

    /// Runs every rule of a seasonal formulary review.
    final class SeasonalFormularyReviewValidator {
        var rules: [any SeasonalFormularyReviewRule]

        init(rules: [any SeasonalFormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalFormularyReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalFormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalFormularyReview]) -> [String: [String]] {
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

    static func defaultSeasonalFormularyReviewValidator() -> SeasonalFormularyReviewValidator {
        return SeasonalFormularyReviewValidator(
            rules: [
                SeasonalFormularyReviewBudgetRangeRule(min: 2.7, max: 1088.0),
                SeasonalFormularyReviewRequiredLabelRule(message: "seasonal formulary review needs an entry"),
                SeasonalFormularyReviewLabelLengthRule(maxLength: 255),
                SeasonalFormularyReviewRequiredTitleRule(message: "seasonal formulary review needs a value"),
                SeasonalFormularyReviewSequenceRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
