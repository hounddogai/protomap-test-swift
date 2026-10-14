import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime schedule must pass. Check returns its problems, or none.
    protocol OvertimeScheduleRule {
        func check(_ item: OvertimeSchedule) -> [String]
    }

    final class OvertimeScheduleAllowedTitleRule: OvertimeScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class OvertimeScheduleTitleLengthRule: OvertimeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeScheduleRequiredCodeRule: OvertimeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeScheduleDurationMinutesRangeRule: OvertimeScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeSchedule) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime schedule.
    final class OvertimeScheduleValidator {
        var rules: [any OvertimeScheduleRule]

        init(rules: [any OvertimeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeSchedule]) -> [String: [String]] {
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

    static func defaultOvertimeScheduleValidator() -> OvertimeScheduleValidator {
        return OvertimeScheduleValidator(
            rules: [
                OvertimeScheduleAllowedTitleRule(allowed: []),
                OvertimeScheduleTitleLengthRule(maxLength: 86400),
                OvertimeScheduleRequiredCodeRule(message: "overtime schedule needs a value"),
                OvertimeScheduleDurationMinutesRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
