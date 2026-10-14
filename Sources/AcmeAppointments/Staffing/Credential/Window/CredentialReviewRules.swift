import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential review must pass. Check returns its problems, or none.
    protocol CredentialReviewRule {
        func check(_ item: CredentialReview) -> [String]
    }

    final class CredentialReviewRequiredPhoneRule: CredentialReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialReviewTitleLengthRule: CredentialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialReviewRevisionRangeRule: CredentialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialReview) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialReviewCodeLengthRule: CredentialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential review.
    final class CredentialReviewValidator {
        var rules: [any CredentialReviewRule]

        init(rules: [any CredentialReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialReview) -> [String] {
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

        func requireValid(_ item: CredentialReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialReview]) -> [String: [String]] {
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

    static func defaultCredentialReviewValidator() -> CredentialReviewValidator {
        return CredentialReviewValidator(
            rules: [
                CredentialReviewRequiredPhoneRule(message: "credential review needs this field"),
                CredentialReviewTitleLengthRule(maxLength: 120),
                CredentialReviewRevisionRangeRule(min: 120, max: 3600),
                CredentialReviewCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
