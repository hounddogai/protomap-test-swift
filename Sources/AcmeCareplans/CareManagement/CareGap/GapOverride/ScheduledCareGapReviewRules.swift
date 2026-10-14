import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled care gap review must pass. Check returns its problems, or none.
    protocol ScheduledCareGapReviewRule {
        func check(_ item: ScheduledCareGapReview) -> [String]
    }

    final class ScheduledCareGapReviewTagsLimitRule: ScheduledCareGapReviewRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ScheduledCareGapReview) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class ScheduledCareGapReviewRequiredCodeRule: ScheduledCareGapReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareGapReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareGapReviewCodeLengthRule: ScheduledCareGapReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareGapReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareGapReviewAmountRangeRule: ScheduledCareGapReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareGapReview) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCareGapReviewRequiredRegionRule: ScheduledCareGapReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareGapReview) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care gap review.
    final class ScheduledCareGapReviewValidator {
        var rules: [any ScheduledCareGapReviewRule]

        init(rules: [any ScheduledCareGapReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareGapReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareGapReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareGapReview]) -> [String: [String]] {
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

    static func defaultScheduledCareGapReviewValidator() -> ScheduledCareGapReviewValidator {
        return ScheduledCareGapReviewValidator(
            rules: [
                ScheduledCareGapReviewTagsLimitRule(maxCount: 3600, banned: ["default", "adaptive", "legacy"]),
                ScheduledCareGapReviewRequiredCodeRule(message: "scheduled care gap review needs an entry"),
                ScheduledCareGapReviewCodeLengthRule(maxLength: 64),
                ScheduledCareGapReviewAmountRangeRule(min: 6.4, max: 2313.2),
                ScheduledCareGapReviewRequiredRegionRule(message: "scheduled care gap review needs a value"),
            ]
        )
    }
}
