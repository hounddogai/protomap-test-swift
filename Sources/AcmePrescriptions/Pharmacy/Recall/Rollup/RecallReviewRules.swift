import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall review must pass. Check returns its problems, or none.
    protocol RecallReviewRule {
        func check(_ item: RecallReview) -> [String]
    }

    final class RecallReviewUpdatedAtRangeRule: RecallReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallReview) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallReviewCodeLengthRule: RecallReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallReviewNameLengthRule: RecallReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall review.
    final class RecallReviewValidator {
        var rules: [any RecallReviewRule]

        init(rules: [any RecallReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallReview) -> [String] {
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

        func requireValid(_ item: RecallReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallReview]) -> [String: [String]] {
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

    static func defaultRecallReviewValidator() -> RecallReviewValidator {
        return RecallReviewValidator(
            rules: [
                RecallReviewUpdatedAtRangeRule(min: 1000, max: 1000),
                RecallReviewCodeLengthRule(maxLength: 86400),
                RecallReviewNameLengthRule(maxLength: 16),
            ]
        )
    }
}
