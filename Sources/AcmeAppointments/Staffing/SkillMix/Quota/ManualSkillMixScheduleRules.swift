import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual skill mix schedule must pass. Check returns its problems, or none.
    protocol ManualSkillMixScheduleRule {
        func check(_ item: ManualSkillMixSchedule) -> [String]
    }

    final class ManualSkillMixScheduleNameLengthRule: ManualSkillMixScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSkillMixSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSkillMixScheduleLabelLengthRule: ManualSkillMixScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSkillMixSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSkillMixScheduleRequiredNameRule: ManualSkillMixScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSkillMixSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSkillMixScheduleCodeLengthRule: ManualSkillMixScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSkillMixSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSkillMixScheduleVersionRangeRule: ManualSkillMixScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSkillMixSchedule) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual skill mix schedule.
    final class ManualSkillMixScheduleValidator {
        var rules: [any ManualSkillMixScheduleRule]

        init(rules: [any ManualSkillMixScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSkillMixSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSkillMixSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSkillMixSchedule]) -> [String: [String]] {
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

    static func defaultManualSkillMixScheduleValidator() -> ManualSkillMixScheduleValidator {
        return ManualSkillMixScheduleValidator(
            rules: [
                ManualSkillMixScheduleNameLengthRule(maxLength: 64),
                ManualSkillMixScheduleLabelLengthRule(maxLength: 16),
                ManualSkillMixScheduleRequiredNameRule(message: "manual skill mix schedule needs a value"),
                ManualSkillMixScheduleCodeLengthRule(maxLength: 3600),
                ManualSkillMixScheduleVersionRangeRule(min: 32, max: 80),
            ]
        )
    }
}
