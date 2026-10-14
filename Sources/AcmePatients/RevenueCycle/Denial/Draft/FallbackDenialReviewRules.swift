import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial review must pass. Check returns its problems, or none.
    protocol FallbackDenialReviewRule {
        func check(_ item: FallbackDenialReview) -> [String]
    }

    final class FallbackDenialReviewLabelLengthRule: FallbackDenialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDenialReviewDurationMinutesRangeRule: FallbackDenialReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialReview) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDenialReviewEncounterIDLengthRule: FallbackDenialReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialReview) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDenialReviewMaximumRangeRule: FallbackDenialReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialReview) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial review.
    final class FallbackDenialReviewValidator {
        var rules: [any FallbackDenialReviewRule]

        init(rules: [any FallbackDenialReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialReview) -> [String] {
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

        func requireValid(_ item: FallbackDenialReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialReview]) -> [String: [String]] {
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

    static func defaultFallbackDenialReviewValidator() -> FallbackDenialReviewValidator {
        return FallbackDenialReviewValidator(
            rules: [
                FallbackDenialReviewLabelLengthRule(maxLength: 16),
                FallbackDenialReviewDurationMinutesRangeRule(min: 16, max: 86400),
                FallbackDenialReviewEncounterIDLengthRule(maxLength: 86400),
                FallbackDenialReviewMaximumRangeRule(min: 8.5, max: 857.0),
            ]
        )
    }
}
