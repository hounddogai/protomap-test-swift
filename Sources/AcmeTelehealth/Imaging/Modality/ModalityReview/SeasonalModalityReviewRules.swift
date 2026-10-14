import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal modality review must pass. Check returns its problems, or none.
    protocol SeasonalModalityReviewRule {
        func check(_ item: SeasonalModalityReview) -> [String]
    }

    final class SeasonalModalityReviewCodeLengthRule: SeasonalModalityReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalModalityReviewContactEmailLengthRule: SeasonalModalityReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalModalityReviewCodePrefixRule: SeasonalModalityReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalModalityReviewRequiredCodeRule: SeasonalModalityReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalModalityReviewWeightRangeRule: SeasonalModalityReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalModalityReviewRequiredContactEmailRule: SeasonalModalityReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalModalityReview) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal modality review.
    final class SeasonalModalityReviewValidator {
        var rules: [any SeasonalModalityReviewRule]

        init(rules: [any SeasonalModalityReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalModalityReview) -> [String] {
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

        func requireValid(_ item: SeasonalModalityReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalModalityReview]) -> [String: [String]] {
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

    static func defaultSeasonalModalityReviewValidator() -> SeasonalModalityReviewValidator {
        return SeasonalModalityReviewValidator(
            rules: [
                SeasonalModalityReviewCodeLengthRule(maxLength: 1000),
                SeasonalModalityReviewContactEmailLengthRule(maxLength: 32),
                SeasonalModalityReviewCodePrefixRule(prefix: "Q"),
                SeasonalModalityReviewRequiredCodeRule(message: "seasonal modality review needs this field"),
                SeasonalModalityReviewWeightRangeRule(min: 5.4, max: 923.8),
                SeasonalModalityReviewRequiredContactEmailRule(message: "seasonal modality review needs an entry"),
            ]
        )
    }
}
