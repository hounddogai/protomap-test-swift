import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy bed board schedule must pass. Check returns its problems, or none.
    protocol LegacyBedBoardScheduleRule {
        func check(_ item: LegacyBedBoardSchedule) -> [String]
    }

    final class LegacyBedBoardScheduleCountryLengthRule: LegacyBedBoardScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardSchedule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyBedBoardScheduleCodeLengthRule: LegacyBedBoardScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyBedBoardScheduleRequiredCodeRule: LegacyBedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyBedBoardSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyBedBoardSchedulePriorityRangeRule: LegacyBedBoardScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyBedBoardSchedule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy bed board schedule.
    final class LegacyBedBoardScheduleValidator {
        var rules: [any LegacyBedBoardScheduleRule]

        init(rules: [any LegacyBedBoardScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyBedBoardSchedule) -> [String] {
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

        func requireValid(_ item: LegacyBedBoardSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyBedBoardSchedule]) -> [String: [String]] {
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

    static func defaultLegacyBedBoardScheduleValidator() -> LegacyBedBoardScheduleValidator {
        return LegacyBedBoardScheduleValidator(
            rules: [
                LegacyBedBoardScheduleCountryLengthRule(maxLength: 16),
                LegacyBedBoardScheduleCodeLengthRule(maxLength: 1000),
                LegacyBedBoardScheduleRequiredCodeRule(message: "legacy bed board schedule needs a value"),
                LegacyBedBoardSchedulePriorityRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
