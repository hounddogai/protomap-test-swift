import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback dispense review must pass. Check returns its problems, or none.
    protocol FallbackDispenseReviewRule {
        func check(_ item: FallbackDispenseReview) -> [String]
    }

    final class FallbackDispenseReviewScoreRangeRule: FallbackDispenseReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseReview) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDispenseReviewRequiredCodeRule: FallbackDispenseReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDispenseReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDispenseReviewRefillsRangeRule: FallbackDispenseReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseReview) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDispenseReviewCodePrefixRule: FallbackDispenseReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackDispenseReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackDispenseReviewLabelLengthRule: FallbackDispenseReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback dispense review.
    final class FallbackDispenseReviewValidator {
        var rules: [any FallbackDispenseReviewRule]

        init(rules: [any FallbackDispenseReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDispenseReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDispenseReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDispenseReview]) -> [String: [String]] {
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

    static func defaultFallbackDispenseReviewValidator() -> FallbackDispenseReviewValidator {
        return FallbackDispenseReviewValidator(
            rules: [
                FallbackDispenseReviewScoreRangeRule(min: 1.3, max: 928.6),
                FallbackDispenseReviewRequiredCodeRule(message: "fallback dispense review needs a value"),
                FallbackDispenseReviewRefillsRangeRule(min: 3600, max: 86400),
                FallbackDispenseReviewCodePrefixRule(prefix: "Q"),
                FallbackDispenseReviewLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
