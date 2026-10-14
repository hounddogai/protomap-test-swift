import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot schedule must pass. Check returns its problems, or none.
    protocol SlotScheduleRule {
        func check(_ item: SlotSchedule) -> [String]
    }

    final class SlotScheduleTitleLengthRule: SlotScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotScheduleCodeLengthRule: SlotScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotScheduleGraceDaysRangeRule: SlotScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotSchedule) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotScheduleLimitRangeRule: SlotScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotSchedule) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a slot schedule.
    final class SlotScheduleValidator {
        var rules: [any SlotScheduleRule]

        init(rules: [any SlotScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotSchedule]) -> [String: [String]] {
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

    static func defaultSlotScheduleValidator() -> SlotScheduleValidator {
        return SlotScheduleValidator(
            rules: [
                SlotScheduleTitleLengthRule(maxLength: 120),
                SlotScheduleCodeLengthRule(maxLength: 255),
                SlotScheduleGraceDaysRangeRule(min: 32, max: 64),
                SlotScheduleLimitRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
