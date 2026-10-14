import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual closure review must pass. Check returns its problems, or none.
    protocol ManualClosureReviewRule {
        func check(_ item: ManualClosureReview) -> [String]
    }

    final class ManualClosureReviewCeilingRangeRule: ManualClosureReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureReview) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualClosureReviewTagsLimitRule: ManualClosureReviewRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ManualClosureReview) -> [String] {
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

    final class ManualClosureReviewRequiredNameRule: ManualClosureReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualClosureReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualClosureReviewScoreRangeRule: ManualClosureReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureReview) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualClosureReviewCapacityRangeRule: ManualClosureReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureReview) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClosureReviewNameLengthRule: ManualClosureReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual closure review.
    final class ManualClosureReviewValidator {
        var rules: [any ManualClosureReviewRule]

        init(rules: [any ManualClosureReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClosureReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualClosureReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClosureReview]) -> [String: [String]] {
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

    static func defaultManualClosureReviewValidator() -> ManualClosureReviewValidator {
        return ManualClosureReviewValidator(
            rules: [
                ManualClosureReviewCeilingRangeRule(min: 2.2, max: 1071.1),
                ManualClosureReviewTagsLimitRule(maxCount: 64, banned: ["tiered"]),
                ManualClosureReviewRequiredNameRule(message: "manual closure review needs a value"),
                ManualClosureReviewScoreRangeRule(min: 4.7, max: 2381.2),
                ManualClosureReviewCapacityRangeRule(min: 32, max: 64),
                ManualClosureReviewNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
