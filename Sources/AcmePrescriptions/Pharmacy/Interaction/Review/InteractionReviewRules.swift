import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction review must pass. Check returns its problems, or none.
    protocol InteractionReviewRule {
        func check(_ item: InteractionReview) -> [String]
    }

    final class InteractionReviewLabelLengthRule: InteractionReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionReviewRetriesRangeRule: InteractionReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionReview) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionReviewCostRangeRule: InteractionReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionReview) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionReviewRequiredLabelRule: InteractionReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction review.
    final class InteractionReviewValidator {
        var rules: [any InteractionReviewRule]

        init(rules: [any InteractionReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionReview]) -> [String: [String]] {
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

    static func defaultInteractionReviewValidator() -> InteractionReviewValidator {
        return InteractionReviewValidator(
            rules: [
                InteractionReviewLabelLengthRule(maxLength: 86400),
                InteractionReviewRetriesRangeRule(min: 80, max: 120),
                InteractionReviewCostRangeRule(min: 9.7, max: 3004.2),
                InteractionReviewRequiredLabelRule(message: "interaction review needs this field"),
            ]
        )
    }
}
