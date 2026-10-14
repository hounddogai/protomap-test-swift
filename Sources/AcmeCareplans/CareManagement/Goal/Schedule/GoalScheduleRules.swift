import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal schedule must pass. Check returns its problems, or none.
    protocol GoalScheduleRule {
        func check(_ item: GoalSchedule) -> [String]
    }

    final class GoalScheduleEncounterIDLengthRule: GoalScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalSchedule) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalScheduleAllowedNameRule: GoalScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class GoalScheduleCostRangeRule: GoalScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalSchedule) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalScheduleRequiredChecksumRule: GoalScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalSchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal schedule.
    final class GoalScheduleValidator {
        var rules: [any GoalScheduleRule]

        init(rules: [any GoalScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalSchedule) -> [String] {
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

        func requireValid(_ item: GoalSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalSchedule]) -> [String: [String]] {
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

    static func defaultGoalScheduleValidator() -> GoalScheduleValidator {
        return GoalScheduleValidator(
            rules: [
                GoalScheduleEncounterIDLengthRule(maxLength: 64),
                GoalScheduleAllowedNameRule(allowed: ["seasonal", "adaptive", "global"]),
                GoalScheduleCostRangeRule(min: 5.1, max: 3795.7),
                GoalScheduleRequiredChecksumRule(message: "goal schedule needs this field"),
            ]
        )
    }
}
