import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling skill mix schedule must pass. Check returns its problems, or none.
    protocol RollingSkillMixScheduleRule {
        func check(_ item: RollingSkillMixSchedule) -> [String]
    }

    final class RollingSkillMixScheduleRequiredClinicianIDRule: RollingSkillMixScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSkillMixSchedule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSkillMixScheduleRequiredCodeRule: RollingSkillMixScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSkillMixSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSkillMixScheduleFloorValueRangeRule: RollingSkillMixScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSkillMixSchedule) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling skill mix schedule.
    final class RollingSkillMixScheduleValidator {
        var rules: [any RollingSkillMixScheduleRule]

        init(rules: [any RollingSkillMixScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSkillMixSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSkillMixSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSkillMixSchedule]) -> [String: [String]] {
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

    static func defaultRollingSkillMixScheduleValidator() -> RollingSkillMixScheduleValidator {
        return RollingSkillMixScheduleValidator(
            rules: [
                RollingSkillMixScheduleRequiredClinicianIDRule(message: "rolling skill mix schedule needs a value"),
                RollingSkillMixScheduleRequiredCodeRule(message: "rolling skill mix schedule needs this field"),
                RollingSkillMixScheduleFloorValueRangeRule(min: 3.7, max: 227.4),
            ]
        )
    }
}
