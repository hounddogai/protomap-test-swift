import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up entry must pass. Check returns its problems, or none.
    protocol FollowUpEntryRule {
        func check(_ item: FollowUpEntry) -> [String]
    }

    final class FollowUpEntryCodePrefixRule: FollowUpEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpEntryVisitMinutesRangeRule: FollowUpEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpEntry) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FollowUpEntryActiveGuardRule: FollowUpEntryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FollowUpEntry) -> [String] {
            if item.active && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FollowUpEntryRequiredTimezoneRule: FollowUpEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpEntry) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpEntryWindowDaysRangeRule: FollowUpEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpEntry) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a follow up entry.
    final class FollowUpEntryValidator {
        var rules: [any FollowUpEntryRule]

        init(rules: [any FollowUpEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpEntry) -> [String] {
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

        func requireValid(_ item: FollowUpEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpEntry]) -> [String: [String]] {
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

    static func defaultFollowUpEntryValidator() -> FollowUpEntryValidator {
        return FollowUpEntryValidator(
            rules: [
                FollowUpEntryCodePrefixRule(prefix: "REF"),
                FollowUpEntryVisitMinutesRangeRule(min: 32, max: 3600),
                FollowUpEntryActiveGuardRule(limit: 16),
                FollowUpEntryRequiredTimezoneRule(message: "follow up entry needs this field"),
                FollowUpEntryWindowDaysRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
