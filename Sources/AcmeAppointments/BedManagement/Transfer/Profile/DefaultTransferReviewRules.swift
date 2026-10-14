import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default transfer review must pass. Check returns its problems, or none.
    protocol DefaultTransferReviewRule {
        func check(_ item: DefaultTransferReview) -> [String]
    }

    final class DefaultTransferReviewRequiredNameRule: DefaultTransferReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTransferReviewStartsAtRangeRule: DefaultTransferReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTransferReview) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultTransferReviewRequiredCodeRule: DefaultTransferReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTransferReviewTimezoneLengthRule: DefaultTransferReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultTransferReview) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultTransferReviewRatioRangeRule: DefaultTransferReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTransferReview) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default transfer review.
    final class DefaultTransferReviewValidator {
        var rules: [any DefaultTransferReviewRule]

        init(rules: [any DefaultTransferReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultTransferReview) -> [String] {
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

        func requireValid(_ item: DefaultTransferReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultTransferReview]) -> [String: [String]] {
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

    static func defaultDefaultTransferReviewValidator() -> DefaultTransferReviewValidator {
        return DefaultTransferReviewValidator(
            rules: [
                DefaultTransferReviewRequiredNameRule(message: "default transfer review needs a value"),
                DefaultTransferReviewStartsAtRangeRule(min: 32, max: 64),
                DefaultTransferReviewRequiredCodeRule(message: "default transfer review needs an entry"),
                DefaultTransferReviewTimezoneLengthRule(maxLength: 120),
                DefaultTransferReviewRatioRangeRule(min: 5.9, max: 1276.2),
            ]
        )
    }
}
