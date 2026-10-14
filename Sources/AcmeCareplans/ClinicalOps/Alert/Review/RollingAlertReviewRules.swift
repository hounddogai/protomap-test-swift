import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling alert review must pass. Check returns its problems, or none.
    protocol RollingAlertReviewRule {
        func check(_ item: RollingAlertReview) -> [String]
    }

    final class RollingAlertReviewCodePrefixRule: RollingAlertReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingAlertReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingAlertReviewReviewerLengthRule: RollingAlertReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAlertReview) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAlertReviewRequiredReviewerRule: RollingAlertReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertReview) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertReviewAmountRangeRule: RollingAlertReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAlertReview) -> [String] {
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

    /// Runs every rule of a rolling alert review.
    final class RollingAlertReviewValidator {
        var rules: [any RollingAlertReviewRule]

        init(rules: [any RollingAlertReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAlertReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAlertReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAlertReview]) -> [String: [String]] {
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

    static func defaultRollingAlertReviewValidator() -> RollingAlertReviewValidator {
        return RollingAlertReviewValidator(
            rules: [
                RollingAlertReviewCodePrefixRule(prefix: "OPS"),
                RollingAlertReviewReviewerLengthRule(maxLength: 255),
                RollingAlertReviewRequiredReviewerRule(message: "rolling alert review needs this field"),
                RollingAlertReviewAmountRangeRule(min: 5.1, max: 651.6),
            ]
        )
    }
}
