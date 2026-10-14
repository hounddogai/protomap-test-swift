import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language review must pass. Check returns its problems, or none.
    protocol LanguageReviewRule {
        func check(_ item: LanguageReview) -> [String]
    }

    final class LanguageReviewArchivedGuardRule: LanguageReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LanguageReview) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LanguageReviewMaximumRangeRule: LanguageReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageReview) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageReviewNameLengthRule: LanguageReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageReviewCodePrefixRule: LanguageReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageReviewCodeLengthRule: LanguageReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageReviewRequiredNameRule: LanguageReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language review.
    final class LanguageReviewValidator {
        var rules: [any LanguageReviewRule]

        init(rules: [any LanguageReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageReview]) -> [String: [String]] {
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

    static func defaultLanguageReviewValidator() -> LanguageReviewValidator {
        return LanguageReviewValidator(
            rules: [
                LanguageReviewArchivedGuardRule(limit: 0.7),
                LanguageReviewMaximumRangeRule(min: 4.3, max: 3487.8),
                LanguageReviewNameLengthRule(maxLength: 120),
                LanguageReviewCodePrefixRule(prefix: "OPS"),
                LanguageReviewCodeLengthRule(maxLength: 16),
                LanguageReviewRequiredNameRule(message: "language review needs a value"),
            ]
        )
    }
}
