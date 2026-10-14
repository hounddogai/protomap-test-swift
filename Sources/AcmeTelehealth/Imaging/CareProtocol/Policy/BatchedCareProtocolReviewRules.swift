import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched care protocol review must pass. Check returns its problems, or none.
    protocol BatchedCareProtocolReviewRule {
        func check(_ item: BatchedCareProtocolReview) -> [String]
    }

    final class BatchedCareProtocolReviewRequiredCodeRule: BatchedCareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCareProtocolReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCareProtocolReviewStartsAtRangeRule: BatchedCareProtocolReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolReview) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolReviewLimitRangeRule: BatchedCareProtocolReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolReview) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched care protocol review.
    final class BatchedCareProtocolReviewValidator {
        var rules: [any BatchedCareProtocolReviewRule]

        init(rules: [any BatchedCareProtocolReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareProtocolReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCareProtocolReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareProtocolReview]) -> [String: [String]] {
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

    static func defaultBatchedCareProtocolReviewValidator() -> BatchedCareProtocolReviewValidator {
        return BatchedCareProtocolReviewValidator(
            rules: [
                BatchedCareProtocolReviewRequiredCodeRule(message: "batched care protocol review needs an entry"),
                BatchedCareProtocolReviewStartsAtRangeRule(min: 16, max: 1000),
                BatchedCareProtocolReviewLimitRangeRule(min: 16, max: 32),
            ]
        )
    }
}
