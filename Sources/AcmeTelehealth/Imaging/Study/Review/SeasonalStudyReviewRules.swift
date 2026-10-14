import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal study review must pass. Check returns its problems, or none.
    protocol SeasonalStudyReviewRule {
        func check(_ item: SeasonalStudyReview) -> [String]
    }

    final class SeasonalStudyReviewCodeLengthRule: SeasonalStudyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStudyReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStudyReviewAttemptsRangeRule: SeasonalStudyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStudyReview) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalStudyReviewAllowedCountryRule: SeasonalStudyReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalStudyReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is expired"]
            }
            return []
        }
    }

    final class SeasonalStudyReviewRequiredUnitRule: SeasonalStudyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStudyReviewSegmentLengthRule: SeasonalStudyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStudyReview) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal study review.
    final class SeasonalStudyReviewValidator {
        var rules: [any SeasonalStudyReviewRule]

        init(rules: [any SeasonalStudyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStudyReview) -> [String] {
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

        func requireValid(_ item: SeasonalStudyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStudyReview]) -> [String: [String]] {
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

    static func defaultSeasonalStudyReviewValidator() -> SeasonalStudyReviewValidator {
        return SeasonalStudyReviewValidator(
            rules: [
                SeasonalStudyReviewCodeLengthRule(maxLength: 255),
                SeasonalStudyReviewAttemptsRangeRule(min: 255, max: 1000),
                SeasonalStudyReviewAllowedCountryRule(allowed: ["batched", "capped", "tiered"]),
                SeasonalStudyReviewRequiredUnitRule(message: "seasonal study review needs this field"),
                SeasonalStudyReviewSegmentLengthRule(maxLength: 80),
            ]
        )
    }
}
