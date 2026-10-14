import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual care protocol review must pass. Check returns its problems, or none.
    protocol ManualCareProtocolReviewRule {
        func check(_ item: ManualCareProtocolReview) -> [String]
    }

    final class ManualCareProtocolReviewAllowedNameRule: ManualCareProtocolReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCareProtocolReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class ManualCareProtocolReviewRegionLengthRule: ManualCareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolReview) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareProtocolReviewTagsLimitRule: ManualCareProtocolReviewRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ManualCareProtocolReview) -> [String] {
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

    final class ManualCareProtocolReviewRequiredNameRule: ManualCareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolReviewTitleLengthRule: ManualCareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care protocol review.
    final class ManualCareProtocolReviewValidator {
        var rules: [any ManualCareProtocolReviewRule]

        init(rules: [any ManualCareProtocolReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolReview) -> [String] {
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

        func requireValid(_ item: ManualCareProtocolReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolReview]) -> [String: [String]] {
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

    static func defaultManualCareProtocolReviewValidator() -> ManualCareProtocolReviewValidator {
        return ManualCareProtocolReviewValidator(
            rules: [
                ManualCareProtocolReviewAllowedNameRule(allowed: ["default", "weighted", "rolling"]),
                ManualCareProtocolReviewRegionLengthRule(maxLength: 1000),
                ManualCareProtocolReviewTagsLimitRule(maxCount: 32, banned: ["tiered", "regional"]),
                ManualCareProtocolReviewRequiredNameRule(message: "manual care protocol review needs this field"),
                ManualCareProtocolReviewTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
