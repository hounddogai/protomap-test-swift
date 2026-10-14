import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling discharge plan schedule must pass. Check returns its problems, or none.
    protocol RollingDischargePlanScheduleRule {
        func check(_ item: RollingDischargePlanSchedule) -> [String]
    }

    final class RollingDischargePlanScheduleRequiredCodeRule: RollingDischargePlanScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanScheduleRequiredCategoryRule: RollingDischargePlanScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanSchedule) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanScheduleLabelLengthRule: RollingDischargePlanScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDischargePlanSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDischargePlanScheduleCodeLengthRule: RollingDischargePlanScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDischargePlanSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling discharge plan schedule.
    final class RollingDischargePlanScheduleValidator {
        var rules: [any RollingDischargePlanScheduleRule]

        init(rules: [any RollingDischargePlanScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDischargePlanSchedule) -> [String] {
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

        func requireValid(_ item: RollingDischargePlanSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDischargePlanSchedule]) -> [String: [String]] {
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

    static func defaultRollingDischargePlanScheduleValidator() -> RollingDischargePlanScheduleValidator {
        return RollingDischargePlanScheduleValidator(
            rules: [
                RollingDischargePlanScheduleRequiredCodeRule(
                    message: "rolling discharge plan schedule needs an entry"
                ),
                RollingDischargePlanScheduleRequiredCategoryRule(
                    message: "rolling discharge plan schedule needs an entry"
                ),
                RollingDischargePlanScheduleLabelLengthRule(maxLength: 80),
                RollingDischargePlanScheduleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
