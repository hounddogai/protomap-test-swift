import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global assessment review must pass. Check returns its problems, or none.
    protocol GlobalAssessmentReviewRule {
        func check(_ item: GlobalAssessmentReview) -> [String]
    }

    final class GlobalAssessmentReviewCurrencyLengthRule: GlobalAssessmentReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAssessmentReviewApprovedGuardRule: GlobalAssessmentReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            if item.approved && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class GlobalAssessmentReviewNameLengthRule: GlobalAssessmentReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAssessmentReviewStartsAtRangeRule: GlobalAssessmentReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAssessmentReviewCodePrefixRule: GlobalAssessmentReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalAssessmentReviewAttemptsRangeRule: GlobalAssessmentReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentReview) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global assessment review.
    final class GlobalAssessmentReviewValidator {
        var rules: [any GlobalAssessmentReviewRule]

        init(rules: [any GlobalAssessmentReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAssessmentReview) -> [String] {
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

        func requireValid(_ item: GlobalAssessmentReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAssessmentReview]) -> [String: [String]] {
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

    static func defaultGlobalAssessmentReviewValidator() -> GlobalAssessmentReviewValidator {
        return GlobalAssessmentReviewValidator(
            rules: [
                GlobalAssessmentReviewCurrencyLengthRule(maxLength: 32),
                GlobalAssessmentReviewApprovedGuardRule(limit: 6.8),
                GlobalAssessmentReviewNameLengthRule(maxLength: 120),
                GlobalAssessmentReviewStartsAtRangeRule(min: 80, max: 1000),
                GlobalAssessmentReviewCodePrefixRule(prefix: "Q"),
                GlobalAssessmentReviewAttemptsRangeRule(min: 32, max: 120),
            ]
        )
    }
}
