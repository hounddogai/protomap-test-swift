import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched credential review must pass. Check returns its problems, or none.
    protocol BatchedCredentialReviewRule {
        func check(_ item: BatchedCredentialReview) -> [String]
    }

    final class BatchedCredentialReviewSequenceRangeRule: BatchedCredentialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCredentialReview) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCredentialReviewRequiredPhoneRule: BatchedCredentialReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCredentialReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCredentialReviewUpdatedAtRangeRule: BatchedCredentialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCredentialReview) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched credential review.
    final class BatchedCredentialReviewValidator {
        var rules: [any BatchedCredentialReviewRule]

        init(rules: [any BatchedCredentialReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCredentialReview) -> [String] {
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

        func requireValid(_ item: BatchedCredentialReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCredentialReview]) -> [String: [String]] {
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

    static func defaultBatchedCredentialReviewValidator() -> BatchedCredentialReviewValidator {
        return BatchedCredentialReviewValidator(
            rules: [
                BatchedCredentialReviewSequenceRangeRule(min: 64, max: 1000),
                BatchedCredentialReviewRequiredPhoneRule(message: "batched credential review needs an entry"),
                BatchedCredentialReviewUpdatedAtRangeRule(min: 64, max: 120),
            ]
        )
    }
}
