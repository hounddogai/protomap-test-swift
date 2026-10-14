import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority schedule must pass. Check returns its problems, or none.
    protocol ScheduledPriorityScheduleRule {
        func check(_ item: ScheduledPrioritySchedule) -> [String]
    }

    final class ScheduledPriorityScheduleLabelLengthRule: ScheduledPriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPrioritySchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPriorityScheduleRequiredOwnerIDRule: ScheduledPriorityScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPrioritySchedule) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPriorityScheduleOwnerIDLengthRule: ScheduledPriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPrioritySchedule) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled priority schedule.
    final class ScheduledPriorityScheduleValidator {
        var rules: [any ScheduledPriorityScheduleRule]

        init(rules: [any ScheduledPriorityScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPrioritySchedule) -> [String] {
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

        func requireValid(_ item: ScheduledPrioritySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPrioritySchedule]) -> [String: [String]] {
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

    static func defaultScheduledPriorityScheduleValidator() -> ScheduledPriorityScheduleValidator {
        return ScheduledPriorityScheduleValidator(
            rules: [
                ScheduledPriorityScheduleLabelLengthRule(maxLength: 255),
                ScheduledPriorityScheduleRequiredOwnerIDRule(message: "scheduled priority schedule needs a value"),
                ScheduledPriorityScheduleOwnerIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
