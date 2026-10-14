import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal order set review must pass. Check returns its problems, or none.
    protocol SeasonalOrderSetReviewRule {
        func check(_ item: SeasonalOrderSetReview) -> [String]
    }

    final class SeasonalOrderSetReviewRequiredPhoneRule: SeasonalOrderSetReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOrderSetReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalOrderSetReviewCodePrefixRule: SeasonalOrderSetReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalOrderSetReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetReviewVersionRangeRule: SeasonalOrderSetReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalOrderSetReview) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalOrderSetReviewRatioRangeRule: SeasonalOrderSetReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalOrderSetReview) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal order set review.
    final class SeasonalOrderSetReviewValidator {
        var rules: [any SeasonalOrderSetReviewRule]

        init(rules: [any SeasonalOrderSetReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOrderSetReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalOrderSetReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOrderSetReview]) -> [String: [String]] {
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

    static func defaultSeasonalOrderSetReviewValidator() -> SeasonalOrderSetReviewValidator {
        return SeasonalOrderSetReviewValidator(
            rules: [
                SeasonalOrderSetReviewRequiredPhoneRule(message: "seasonal order set review needs an entry"),
                SeasonalOrderSetReviewCodePrefixRule(prefix: "ACM"),
                SeasonalOrderSetReviewVersionRangeRule(min: 16, max: 64),
                SeasonalOrderSetReviewRatioRangeRule(min: 3.7, max: 2368.1),
            ]
        )
    }
}
