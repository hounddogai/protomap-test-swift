import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding draft must pass. Check returns its problems, or none.
    protocol RoundingDraftRule {
        func check(_ item: RoundingDraft) -> [String]
    }

    final class RoundingDraftEndsAtRangeRule: RoundingDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingDraft) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingDraftVisitMinutesRangeRule: RoundingDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingDraft) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingDraftRequiredTitleRule: RoundingDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingDraftTitleLengthRule: RoundingDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingDraftTagsLimitRule: RoundingDraftRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RoundingDraft) -> [String] {
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

    /// Runs every rule of a rounding draft.
    final class RoundingDraftValidator {
        var rules: [any RoundingDraftRule]

        init(rules: [any RoundingDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingDraft) -> [String] {
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

        func requireValid(_ item: RoundingDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingDraft]) -> [String: [String]] {
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

    static func defaultRoundingDraftValidator() -> RoundingDraftValidator {
        return RoundingDraftValidator(
            rules: [
                RoundingDraftEndsAtRangeRule(min: 32, max: 86400),
                RoundingDraftVisitMinutesRangeRule(min: 1000, max: 3600),
                RoundingDraftRequiredTitleRule(message: "rounding draft needs this field"),
                RoundingDraftTitleLengthRule(maxLength: 255),
                RoundingDraftTagsLimitRule(maxCount: 16, banned: ["primary"]),
            ]
        )
    }
}
