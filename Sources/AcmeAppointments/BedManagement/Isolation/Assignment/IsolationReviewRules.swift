import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation review must pass. Check returns its problems, or none.
    protocol IsolationReviewRule {
        func check(_ item: IsolationReview) -> [String]
    }

    final class IsolationReviewRequiredPhoneRule: IsolationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationReviewDescriptionLengthRule: IsolationReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationReviewAllowedPayerRule: IsolationReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is missing"]
            }
            return []
        }
    }

    final class IsolationReviewVisibleGuardRule: IsolationReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: IsolationReview) -> [String] {
            if item.visible && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation review.
    final class IsolationReviewValidator {
        var rules: [any IsolationReviewRule]

        init(rules: [any IsolationReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationReview) -> [String] {
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

        func requireValid(_ item: IsolationReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationReview]) -> [String: [String]] {
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

    static func defaultIsolationReviewValidator() -> IsolationReviewValidator {
        return IsolationReviewValidator(
            rules: [
                IsolationReviewRequiredPhoneRule(message: "isolation review needs this field"),
                IsolationReviewDescriptionLengthRule(maxLength: 16),
                IsolationReviewAllowedPayerRule(allowed: []),
                IsolationReviewVisibleGuardRule(limit: 3600),
            ]
        )
    }
}
