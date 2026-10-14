import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled closure draft must pass. Check returns its problems, or none.
    protocol ScheduledClosureDraftRule {
        func check(_ item: ScheduledClosureDraft) -> [String]
    }

    final class ScheduledClosureDraftRequiredCodeRule: ScheduledClosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClosureDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClosureDraftAllowedNameRule: ScheduledClosureDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledClosureDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class ScheduledClosureDraftRequiredNameRule: ScheduledClosureDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClosureDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClosureDraftNameLengthRule: ScheduledClosureDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClosureDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled closure draft.
    final class ScheduledClosureDraftValidator {
        var rules: [any ScheduledClosureDraftRule]

        init(rules: [any ScheduledClosureDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClosureDraft) -> [String] {
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

        func requireValid(_ item: ScheduledClosureDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClosureDraft]) -> [String: [String]] {
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

    static func defaultScheduledClosureDraftValidator() -> ScheduledClosureDraftValidator {
        return ScheduledClosureDraftValidator(
            rules: [
                ScheduledClosureDraftRequiredCodeRule(message: "scheduled closure draft needs an entry"),
                ScheduledClosureDraftAllowedNameRule(allowed: ["primary"]),
                ScheduledClosureDraftRequiredNameRule(message: "scheduled closure draft needs this field"),
                ScheduledClosureDraftNameLengthRule(maxLength: 16),
            ]
        )
    }
}
