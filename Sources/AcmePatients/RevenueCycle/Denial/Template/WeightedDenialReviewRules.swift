import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted denial review must pass. Check returns its problems, or none.
    protocol WeightedDenialReviewRule {
        func check(_ item: WeightedDenialReview) -> [String]
    }

    final class WeightedDenialReviewNameLengthRule: WeightedDenialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDenialReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDenialReviewAllowedNameRule: WeightedDenialReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedDenialReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class WeightedDenialReviewVisibleGuardRule: WeightedDenialReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedDenialReview) -> [String] {
            if item.visible && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WeightedDenialReviewCostRangeRule: WeightedDenialReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDenialReview) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedDenialReviewCurrencyLengthRule: WeightedDenialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDenialReview) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted denial review.
    final class WeightedDenialReviewValidator {
        var rules: [any WeightedDenialReviewRule]

        init(rules: [any WeightedDenialReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDenialReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDenialReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDenialReview]) -> [String: [String]] {
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

    static func defaultWeightedDenialReviewValidator() -> WeightedDenialReviewValidator {
        return WeightedDenialReviewValidator(
            rules: [
                WeightedDenialReviewNameLengthRule(maxLength: 64),
                WeightedDenialReviewAllowedNameRule(allowed: ["rolling", "lenient"]),
                WeightedDenialReviewVisibleGuardRule(limit: 255),
                WeightedDenialReviewCostRangeRule(min: 5.2, max: 1705.4),
                WeightedDenialReviewCurrencyLengthRule(maxLength: 255),
            ]
        )
    }
}
