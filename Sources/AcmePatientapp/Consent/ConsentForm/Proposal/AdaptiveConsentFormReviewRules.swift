import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive consent form review must pass. Check returns its problems, or none.
    protocol AdaptiveConsentFormReviewRule {
        func check(_ item: AdaptiveConsentFormReview) -> [String]
    }

    final class AdaptiveConsentFormReviewWindowDaysRangeRule: AdaptiveConsentFormReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveConsentFormReview) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveConsentFormReviewAllowedDescriptionRule: AdaptiveConsentFormReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveConsentFormReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormReviewNameLengthRule: AdaptiveConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormReviewPhoneLengthRule: AdaptiveConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormReview) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormReviewRequiredNameRule: AdaptiveConsentFormReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive consent form review.
    final class AdaptiveConsentFormReviewValidator {
        var rules: [any AdaptiveConsentFormReviewRule]

        init(rules: [any AdaptiveConsentFormReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveConsentFormReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveConsentFormReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveConsentFormReview]) -> [String: [String]] {
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

    static func defaultAdaptiveConsentFormReviewValidator() -> AdaptiveConsentFormReviewValidator {
        return AdaptiveConsentFormReviewValidator(
            rules: [
                AdaptiveConsentFormReviewWindowDaysRangeRule(min: 80, max: 120),
                AdaptiveConsentFormReviewAllowedDescriptionRule(allowed: ["fallback"]),
                AdaptiveConsentFormReviewNameLengthRule(maxLength: 120),
                AdaptiveConsentFormReviewPhoneLengthRule(maxLength: 1000),
                AdaptiveConsentFormReviewRequiredNameRule(message: "adaptive consent form review needs this field"),
            ]
        )
    }
}
