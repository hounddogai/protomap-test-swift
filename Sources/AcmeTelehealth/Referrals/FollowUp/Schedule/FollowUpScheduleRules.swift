import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up schedule must pass. Check returns its problems, or none.
    protocol FollowUpScheduleRule {
        func check(_ item: FollowUpSchedule) -> [String]
    }

    final class FollowUpScheduleCodePrefixRule: FollowUpScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpScheduleNameLengthRule: FollowUpScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpScheduleOwnerIDLengthRule: FollowUpScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSchedule) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up schedule.
    final class FollowUpScheduleValidator {
        var rules: [any FollowUpScheduleRule]

        init(rules: [any FollowUpScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpSchedule) -> [String] {
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

        func requireValid(_ item: FollowUpSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpSchedule]) -> [String: [String]] {
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

    static func defaultFollowUpScheduleValidator() -> FollowUpScheduleValidator {
        return FollowUpScheduleValidator(
            rules: [
                FollowUpScheduleCodePrefixRule(prefix: "ACM"),
                FollowUpScheduleNameLengthRule(maxLength: 3600),
                FollowUpScheduleOwnerIDLengthRule(maxLength: 16),
            ]
        )
    }
}
