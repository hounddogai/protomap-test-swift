import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary credential review must pass. Check returns its problems, or none.
    protocol PrimaryCredentialReviewRule {
        func check(_ item: PrimaryCredentialReview) -> [String]
    }

    final class PrimaryCredentialReviewCodeLengthRule: PrimaryCredentialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCredentialReviewRefillsRangeRule: PrimaryCredentialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialReview) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryCredentialReviewStartsAtRangeRule: PrimaryCredentialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialReview) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCredentialReviewRequiredLabelRule: PrimaryCredentialReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary credential review.
    final class PrimaryCredentialReviewValidator {
        var rules: [any PrimaryCredentialReviewRule]

        init(rules: [any PrimaryCredentialReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCredentialReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCredentialReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCredentialReview]) -> [String: [String]] {
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

    static func defaultPrimaryCredentialReviewValidator() -> PrimaryCredentialReviewValidator {
        return PrimaryCredentialReviewValidator(
            rules: [
                PrimaryCredentialReviewCodeLengthRule(maxLength: 120),
                PrimaryCredentialReviewRefillsRangeRule(min: 32, max: 120),
                PrimaryCredentialReviewStartsAtRangeRule(min: 80, max: 255),
                PrimaryCredentialReviewRequiredLabelRule(message: "primary credential review needs a value"),
            ]
        )
    }
}
