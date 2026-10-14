import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive bed board review must pass. Check returns its problems, or none.
    protocol AdaptiveBedBoardReviewRule {
        func check(_ item: AdaptiveBedBoardReview) -> [String]
    }

    final class AdaptiveBedBoardReviewLimitRangeRule: AdaptiveBedBoardReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveBedBoardReview) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardReviewAllowedUnitRule: AdaptiveBedBoardReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveBedBoardReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is below minimum"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardReviewRequiredCodeRule: AdaptiveBedBoardReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveBedBoardReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveBedBoardReviewRatioRangeRule: AdaptiveBedBoardReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveBedBoardReview) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveBedBoardReviewRequiredUnitRule: AdaptiveBedBoardReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveBedBoardReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive bed board review.
    final class AdaptiveBedBoardReviewValidator {
        var rules: [any AdaptiveBedBoardReviewRule]

        init(rules: [any AdaptiveBedBoardReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveBedBoardReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveBedBoardReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveBedBoardReview]) -> [String: [String]] {
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

    static func defaultAdaptiveBedBoardReviewValidator() -> AdaptiveBedBoardReviewValidator {
        return AdaptiveBedBoardReviewValidator(
            rules: [
                AdaptiveBedBoardReviewLimitRangeRule(min: 255, max: 1000),
                AdaptiveBedBoardReviewAllowedUnitRule(allowed: []),
                AdaptiveBedBoardReviewRequiredCodeRule(message: "adaptive bed board review needs this field"),
                AdaptiveBedBoardReviewRatioRangeRule(min: 5.9, max: 4298.2),
                AdaptiveBedBoardReviewRequiredUnitRule(message: "adaptive bed board review needs a value"),
            ]
        )
    }
}
