import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled language review must pass. Check returns its problems, or none.
    protocol ScheduledLanguageReviewRule {
        func check(_ item: ScheduledLanguageReview) -> [String]
    }

    final class ScheduledLanguageReviewRequiredNameRule: ScheduledLanguageReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledLanguageReviewCapacityRangeRule: ScheduledLanguageReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledLanguageReviewNameLengthRule: ScheduledLanguageReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageReviewReviewerLengthRule: ScheduledLanguageReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageReviewAllowedCodeRule: ScheduledLanguageReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class ScheduledLanguageReviewCodePrefixRule: ScheduledLanguageReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledLanguageReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled language review.
    final class ScheduledLanguageReviewValidator {
        var rules: [any ScheduledLanguageReviewRule]

        init(rules: [any ScheduledLanguageReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledLanguageReview) -> [String] {
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

        func requireValid(_ item: ScheduledLanguageReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledLanguageReview]) -> [String: [String]] {
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

    static func defaultScheduledLanguageReviewValidator() -> ScheduledLanguageReviewValidator {
        return ScheduledLanguageReviewValidator(
            rules: [
                ScheduledLanguageReviewRequiredNameRule(message: "scheduled language review needs this field"),
                ScheduledLanguageReviewCapacityRangeRule(min: 255, max: 3600),
                ScheduledLanguageReviewNameLengthRule(maxLength: 80),
                ScheduledLanguageReviewReviewerLengthRule(maxLength: 1000),
                ScheduledLanguageReviewAllowedCodeRule(allowed: ["default", "adaptive"]),
                ScheduledLanguageReviewCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
