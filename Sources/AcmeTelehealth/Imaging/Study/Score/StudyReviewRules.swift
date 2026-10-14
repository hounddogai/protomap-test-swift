import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study review must pass. Check returns its problems, or none.
    protocol StudyReviewRule {
        func check(_ item: StudyReview) -> [String]
    }

    final class StudyReviewTagsLimitRule: StudyReviewRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StudyReview) -> [String] {
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

    final class StudyReviewAttemptsRangeRule: StudyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyReview) -> [String] {
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

    final class StudyReviewPinnedGuardRule: StudyReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StudyReview) -> [String] {
            if item.pinned && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StudyReviewTitleLengthRule: StudyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyReviewCodeLengthRule: StudyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study review.
    final class StudyReviewValidator {
        var rules: [any StudyReviewRule]

        init(rules: [any StudyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyReview]) -> [String: [String]] {
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

    static func defaultStudyReviewValidator() -> StudyReviewValidator {
        return StudyReviewValidator(
            rules: [
                StudyReviewTagsLimitRule(maxCount: 32, banned: ["legacy"]),
                StudyReviewAttemptsRangeRule(min: 16, max: 255),
                StudyReviewPinnedGuardRule(limit: 255),
                StudyReviewTitleLengthRule(maxLength: 120),
                StudyReviewCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
