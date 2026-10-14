import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment review must pass. Check returns its problems, or none.
    protocol AssessmentReviewRule {
        func check(_ item: AssessmentReview) -> [String]
    }

    final class AssessmentReviewDescriptionLengthRule: AssessmentReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentReviewDiscountRangeRule: AssessmentReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentReview) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentReviewCodeLengthRule: AssessmentReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentReviewCreatedAtRangeRule: AssessmentReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentReview) -> [String] {
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

    /// Runs every rule of a assessment review.
    final class AssessmentReviewValidator {
        var rules: [any AssessmentReviewRule]

        init(rules: [any AssessmentReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentReview) -> [String] {
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

        func requireValid(_ item: AssessmentReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentReview]) -> [String: [String]] {
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

    static func defaultAssessmentReviewValidator() -> AssessmentReviewValidator {
        return AssessmentReviewValidator(
            rules: [
                AssessmentReviewDescriptionLengthRule(maxLength: 64),
                AssessmentReviewDiscountRangeRule(min: 4.2, max: 2174.5),
                AssessmentReviewCodeLengthRule(maxLength: 86400),
                AssessmentReviewCreatedAtRangeRule(min: 16, max: 255),
            ]
        )
    }
}
