import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending claim review must pass. Check returns its problems, or none.
    protocol PendingClaimReviewRule {
        func check(_ item: PendingClaimReview) -> [String]
    }

    final class PendingClaimReviewCodeLengthRule: PendingClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingClaimReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingClaimReviewCapacityRangeRule: PendingClaimReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimReview) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingClaimReviewAmountRangeRule: PendingClaimReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimReview) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending claim review.
    final class PendingClaimReviewValidator {
        var rules: [any PendingClaimReviewRule]

        init(rules: [any PendingClaimReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingClaimReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingClaimReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingClaimReview]) -> [String: [String]] {
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

    static func defaultPendingClaimReviewValidator() -> PendingClaimReviewValidator {
        return PendingClaimReviewValidator(
            rules: [
                PendingClaimReviewCodeLengthRule(maxLength: 86400),
                PendingClaimReviewCapacityRangeRule(min: 120, max: 255),
                PendingClaimReviewAmountRangeRule(min: 2.0, max: 4159.6),
            ]
        )
    }
}
