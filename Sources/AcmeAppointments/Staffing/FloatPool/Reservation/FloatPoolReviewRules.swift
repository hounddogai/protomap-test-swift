import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool review must pass. Check returns its problems, or none.
    protocol FloatPoolReviewRule {
        func check(_ item: FloatPoolReview) -> [String]
    }

    final class FloatPoolReviewBudgetRangeRule: FloatPoolReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolReview) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolReviewTitleLengthRule: FloatPoolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolReviewRateRangeRule: FloatPoolReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolReview) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolReviewRequiredAllergyRule: FloatPoolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolReview) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a float pool review.
    final class FloatPoolReviewValidator {
        var rules: [any FloatPoolReviewRule]

        init(rules: [any FloatPoolReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolReview) -> [String] {
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

        func requireValid(_ item: FloatPoolReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolReview]) -> [String: [String]] {
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

    static func defaultFloatPoolReviewValidator() -> FloatPoolReviewValidator {
        return FloatPoolReviewValidator(
            rules: [
                FloatPoolReviewBudgetRangeRule(min: 9.7, max: 4302.7),
                FloatPoolReviewTitleLengthRule(maxLength: 255),
                FloatPoolReviewRateRangeRule(min: 1.3, max: 3756.9),
                FloatPoolReviewRequiredAllergyRule(message: "float pool review needs an entry"),
            ]
        )
    }
}
