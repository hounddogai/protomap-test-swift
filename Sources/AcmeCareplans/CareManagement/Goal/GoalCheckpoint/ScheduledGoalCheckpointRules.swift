import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled goal checkpoint must pass. Check returns its problems, or none.
    protocol ScheduledGoalCheckpointRule {
        func check(_ item: ScheduledGoalCheckpoint) -> [String]
    }

    final class ScheduledGoalCheckpointBudgetRangeRule: ScheduledGoalCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledGoalCheckpointTimezoneLengthRule: ScheduledGoalCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalCheckpointRequiredCodeRule: ScheduledGoalCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalCheckpointSequenceRangeRule: ScheduledGoalCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledGoalCheckpointAllowedCodeRule: ScheduledGoalCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ScheduledGoalCheckpointCodeLengthRule: ScheduledGoalCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled goal checkpoint.
    final class ScheduledGoalCheckpointValidator {
        var rules: [any ScheduledGoalCheckpointRule]

        init(rules: [any ScheduledGoalCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledGoalCheckpoint) -> [String] {
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

        func requireValid(_ item: ScheduledGoalCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledGoalCheckpoint]) -> [String: [String]] {
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

    static func defaultScheduledGoalCheckpointValidator() -> ScheduledGoalCheckpointValidator {
        return ScheduledGoalCheckpointValidator(
            rules: [
                ScheduledGoalCheckpointBudgetRangeRule(min: 8.5, max: 1377.8),
                ScheduledGoalCheckpointTimezoneLengthRule(maxLength: 3600),
                ScheduledGoalCheckpointRequiredCodeRule(message: "scheduled goal checkpoint needs this field"),
                ScheduledGoalCheckpointSequenceRangeRule(min: 16, max: 1000),
                ScheduledGoalCheckpointAllowedCodeRule(allowed: ["pending", "capped", "rolling"]),
                ScheduledGoalCheckpointCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
