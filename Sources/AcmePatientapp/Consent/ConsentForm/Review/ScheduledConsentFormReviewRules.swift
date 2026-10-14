import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled consent form review must pass. Check returns its problems, or none.
    protocol ScheduledConsentFormReviewRule {
        func check(_ item: ScheduledConsentFormReview) -> [String]
    }

    final class ScheduledConsentFormReviewRequiredSummaryRule: ScheduledConsentFormReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledConsentFormReview) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledConsentFormReviewNameLengthRule: ScheduledConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormReviewRequiredNameRule: ScheduledConsentFormReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledConsentFormReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledConsentFormReviewQuantityRangeRule: ScheduledConsentFormReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormReview) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled consent form review.
    final class ScheduledConsentFormReviewValidator {
        var rules: [any ScheduledConsentFormReviewRule]

        init(rules: [any ScheduledConsentFormReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledConsentFormReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledConsentFormReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledConsentFormReview]) -> [String: [String]] {
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

    static func defaultScheduledConsentFormReviewValidator() -> ScheduledConsentFormReviewValidator {
        return ScheduledConsentFormReviewValidator(
            rules: [
                ScheduledConsentFormReviewRequiredSummaryRule(message: "scheduled consent form review needs a value"),
                ScheduledConsentFormReviewNameLengthRule(maxLength: 255),
                ScheduledConsentFormReviewRequiredNameRule(message: "scheduled consent form review needs a value"),
                ScheduledConsentFormReviewQuantityRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
