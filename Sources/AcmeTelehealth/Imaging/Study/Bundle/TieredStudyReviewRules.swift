import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study review must pass. Check returns its problems, or none.
    protocol TieredStudyReviewRule {
        func check(_ item: TieredStudyReview) -> [String]
    }

    final class TieredStudyReviewCodePrefixRule: TieredStudyReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredStudyReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredStudyReviewRequiredCurrencyRule: TieredStudyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStudyReview) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredStudyReviewUnitLengthRule: TieredStudyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyReview) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudyReviewRefillsRangeRule: TieredStudyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudyReview) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered study review.
    final class TieredStudyReviewValidator {
        var rules: [any TieredStudyReviewRule]

        init(rules: [any TieredStudyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudyReview) -> [String] {
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

        func requireValid(_ item: TieredStudyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudyReview]) -> [String: [String]] {
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

    static func defaultTieredStudyReviewValidator() -> TieredStudyReviewValidator {
        return TieredStudyReviewValidator(
            rules: [
                TieredStudyReviewCodePrefixRule(prefix: "X"),
                TieredStudyReviewRequiredCurrencyRule(message: "tiered study review needs this field"),
                TieredStudyReviewUnitLengthRule(maxLength: 64),
                TieredStudyReviewRefillsRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
