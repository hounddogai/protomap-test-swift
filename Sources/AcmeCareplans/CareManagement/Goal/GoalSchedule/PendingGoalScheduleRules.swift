import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending goal schedule must pass. Check returns its problems, or none.
    protocol PendingGoalScheduleRule {
        func check(_ item: PendingGoalSchedule) -> [String]
    }

    final class PendingGoalScheduleAllowedSpecialtyRule: PendingGoalScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingGoalSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is inconsistent"]
            }
            return []
        }
    }

    final class PendingGoalScheduleBedLengthRule: PendingGoalScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingGoalSchedule) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingGoalScheduleWeightRangeRule: PendingGoalScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingGoalSchedule) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending goal schedule.
    final class PendingGoalScheduleValidator {
        var rules: [any PendingGoalScheduleRule]

        init(rules: [any PendingGoalScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingGoalSchedule) -> [String] {
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

        func requireValid(_ item: PendingGoalSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingGoalSchedule]) -> [String: [String]] {
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

    static func defaultPendingGoalScheduleValidator() -> PendingGoalScheduleValidator {
        return PendingGoalScheduleValidator(
            rules: [
                PendingGoalScheduleAllowedSpecialtyRule(allowed: ["regional"]),
                PendingGoalScheduleBedLengthRule(maxLength: 16),
                PendingGoalScheduleWeightRangeRule(min: 3.4, max: 1222.2),
            ]
        )
    }
}
