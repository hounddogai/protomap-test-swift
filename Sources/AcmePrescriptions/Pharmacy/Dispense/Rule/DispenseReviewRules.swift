import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense review must pass. Check returns its problems, or none.
    protocol DispenseReviewRule {
        func check(_ item: DispenseReview) -> [String]
    }

    final class DispenseReviewRequiredLocaleRule: DispenseReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseReview) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseReviewGraceDaysRangeRule: DispenseReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseReview) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseReviewCodePrefixRule: DispenseReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseReviewCodeLengthRule: DispenseReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense review.
    final class DispenseReviewValidator {
        var rules: [any DispenseReviewRule]

        init(rules: [any DispenseReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseReview]) -> [String: [String]] {
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

    static func defaultDispenseReviewValidator() -> DispenseReviewValidator {
        return DispenseReviewValidator(
            rules: [
                DispenseReviewRequiredLocaleRule(message: "dispense review needs a value"),
                DispenseReviewGraceDaysRangeRule(min: 32, max: 64),
                DispenseReviewCodePrefixRule(prefix: "Q"),
                DispenseReviewCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
