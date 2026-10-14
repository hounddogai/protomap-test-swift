import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled specimen draft must pass. Check returns its problems, or none.
    protocol ScheduledSpecimenDraftRule {
        func check(_ item: ScheduledSpecimenDraft) -> [String]
    }

    final class ScheduledSpecimenDraftRequiredFacilityRule: ScheduledSpecimenDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSpecimenDraft) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledSpecimenDraftTagsLimitRule: ScheduledSpecimenDraftRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ScheduledSpecimenDraft) -> [String] {
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

    final class ScheduledSpecimenDraftSequenceRangeRule: ScheduledSpecimenDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSpecimenDraft) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledSpecimenDraftCodePrefixRule: ScheduledSpecimenDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledSpecimenDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledSpecimenDraftContactEmailLengthRule: ScheduledSpecimenDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSpecimenDraft) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled specimen draft.
    final class ScheduledSpecimenDraftValidator {
        var rules: [any ScheduledSpecimenDraftRule]

        init(rules: [any ScheduledSpecimenDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledSpecimenDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledSpecimenDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledSpecimenDraft]) -> [String: [String]] {
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

    static func defaultScheduledSpecimenDraftValidator() -> ScheduledSpecimenDraftValidator {
        return ScheduledSpecimenDraftValidator(
            rules: [
                ScheduledSpecimenDraftRequiredFacilityRule(message: "scheduled specimen draft needs a value"),
                ScheduledSpecimenDraftTagsLimitRule(maxCount: 1000, banned: ["default", "fallback", "pending"]),
                ScheduledSpecimenDraftSequenceRangeRule(min: 32, max: 120),
                ScheduledSpecimenDraftCodePrefixRule(prefix: "REF"),
                ScheduledSpecimenDraftContactEmailLengthRule(maxLength: 64),
            ]
        )
    }
}
