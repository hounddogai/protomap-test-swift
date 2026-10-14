import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy review must pass. Check returns its problems, or none.
    protocol LenientProxyReviewRule {
        func check(_ item: LenientProxyReview) -> [String]
    }

    final class LenientProxyReviewCodeLengthRule: LenientProxyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProxyReviewRequiredTimezoneRule: LenientProxyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyReview) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyReviewQuantityRangeRule: LenientProxyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyReview) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy review.
    final class LenientProxyReviewValidator {
        var rules: [any LenientProxyReviewRule]

        init(rules: [any LenientProxyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyReview) -> [String] {
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

        func requireValid(_ item: LenientProxyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyReview]) -> [String: [String]] {
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

    static func defaultLenientProxyReviewValidator() -> LenientProxyReviewValidator {
        return LenientProxyReviewValidator(
            rules: [
                LenientProxyReviewCodeLengthRule(maxLength: 80),
                LenientProxyReviewRequiredTimezoneRule(message: "lenient proxy review needs an entry"),
                LenientProxyReviewQuantityRangeRule(min: 16, max: 32),
            ]
        )
    }
}
