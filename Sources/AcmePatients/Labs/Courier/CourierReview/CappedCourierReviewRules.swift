import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped courier review must pass. Check returns its problems, or none.
    protocol CappedCourierReviewRule {
        func check(_ item: CappedCourierReview) -> [String]
    }

    final class CappedCourierReviewRequiredCodeRule: CappedCourierReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCourierReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCourierReviewDurationMinutesRangeRule: CappedCourierReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCourierReview) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCourierReviewRequiredTitleRule: CappedCourierReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCourierReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped courier review.
    final class CappedCourierReviewValidator {
        var rules: [any CappedCourierReviewRule]

        init(rules: [any CappedCourierReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCourierReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCourierReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCourierReview]) -> [String: [String]] {
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

    static func defaultCappedCourierReviewValidator() -> CappedCourierReviewValidator {
        return CappedCourierReviewValidator(
            rules: [
                CappedCourierReviewRequiredCodeRule(message: "capped courier review needs an entry"),
                CappedCourierReviewDurationMinutesRangeRule(min: 120, max: 120),
                CappedCourierReviewRequiredTitleRule(message: "capped courier review needs this field"),
            ]
        )
    }
}
