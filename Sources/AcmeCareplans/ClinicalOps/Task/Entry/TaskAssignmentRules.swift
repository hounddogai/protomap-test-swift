import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task assignment must pass. Check returns its problems, or none.
    protocol TaskAssignmentRule {
        func check(_ item: TaskAssignment) -> [String]
    }

    final class TaskAssignmentCreatedAtRangeRule: TaskAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskAssignment) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskAssignmentEncounterIDLengthRule: TaskAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskAssignment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskAssignmentVersionRangeRule: TaskAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskAssignment) -> [String] {
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

    final class TaskAssignmentApprovedGuardRule: TaskAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TaskAssignment) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TaskAssignmentCodeLengthRule: TaskAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskAssignmentDiscountRangeRule: TaskAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskAssignment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a task assignment.
    final class TaskAssignmentValidator {
        var rules: [any TaskAssignmentRule]

        init(rules: [any TaskAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskAssignment) -> [String] {
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

        func requireValid(_ item: TaskAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskAssignment]) -> [String: [String]] {
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

    static func defaultTaskAssignmentValidator() -> TaskAssignmentValidator {
        return TaskAssignmentValidator(
            rules: [
                TaskAssignmentCreatedAtRangeRule(min: 120, max: 120),
                TaskAssignmentEncounterIDLengthRule(maxLength: 64),
                TaskAssignmentVersionRangeRule(min: 255, max: 1000),
                TaskAssignmentApprovedGuardRule(limit: 80),
                TaskAssignmentCodeLengthRule(maxLength: 1000),
                TaskAssignmentDiscountRangeRule(min: 9.8, max: 4601.6),
            ]
        )
    }
}
