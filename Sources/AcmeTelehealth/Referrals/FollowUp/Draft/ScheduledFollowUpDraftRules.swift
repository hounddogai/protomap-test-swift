import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up draft must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpDraftRule {
        func check(_ item: ScheduledFollowUpDraft) -> [String]
    }

    final class ScheduledFollowUpDraftApprovedGuardRule: ScheduledFollowUpDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ScheduledFollowUpDraftCodePrefixRule: ScheduledFollowUpDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpDraftAllowedCodeRule: ScheduledFollowUpDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ScheduledFollowUpDraftCodeLengthRule: ScheduledFollowUpDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpDraftLimitRangeRule: ScheduledFollowUpDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpDraftRequiredExternalRefRule: ScheduledFollowUpDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpDraft) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up draft.
    final class ScheduledFollowUpDraftValidator {
        var rules: [any ScheduledFollowUpDraftRule]

        init(rules: [any ScheduledFollowUpDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpDraft) -> [String] {
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

        func requireValid(_ item: ScheduledFollowUpDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpDraft]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpDraftValidator() -> ScheduledFollowUpDraftValidator {
        return ScheduledFollowUpDraftValidator(
            rules: [
                ScheduledFollowUpDraftApprovedGuardRule(limit: 120),
                ScheduledFollowUpDraftCodePrefixRule(prefix: "OPS"),
                ScheduledFollowUpDraftAllowedCodeRule(allowed: ["weighted", "strict", "lenient"]),
                ScheduledFollowUpDraftCodeLengthRule(maxLength: 80),
                ScheduledFollowUpDraftLimitRangeRule(min: 16, max: 255),
                ScheduledFollowUpDraftRequiredExternalRefRule(message: "scheduled follow up draft needs a value"),
            ]
        )
    }
}
