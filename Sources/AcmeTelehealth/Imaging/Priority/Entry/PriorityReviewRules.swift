import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority review must pass. Check returns its problems, or none.
    protocol PriorityReviewRule {
        func check(_ item: PriorityReview) -> [String]
    }

    final class PriorityReviewRequiredCategoryRule: PriorityReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityReview) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityReviewVisibleGuardRule: PriorityReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PriorityReview) -> [String] {
            if item.visible && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PriorityReviewNameLengthRule: PriorityReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority review.
    final class PriorityReviewValidator {
        var rules: [any PriorityReviewRule]

        init(rules: [any PriorityReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityReview]) -> [String: [String]] {
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

    static func defaultPriorityReviewValidator() -> PriorityReviewValidator {
        return PriorityReviewValidator(
            rules: [
                PriorityReviewRequiredCategoryRule(message: "priority review needs an entry"),
                PriorityReviewVisibleGuardRule(limit: 6.7),
                PriorityReviewNameLengthRule(maxLength: 16),
            ]
        )
    }
}
