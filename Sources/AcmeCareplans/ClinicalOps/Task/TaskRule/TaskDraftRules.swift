import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task draft must pass. Check returns its problems, or none.
    protocol TaskDraftRule {
        func check(_ item: TaskDraft) -> [String]
    }

    final class TaskDraftUpdatedAtRangeRule: TaskDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskDraft) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskDraftReviewerLengthRule: TaskDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskDraft) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskDraftAllowedLabelRule: TaskDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class TaskDraftCodeLengthRule: TaskDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskDraftLabelLengthRule: TaskDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task draft.
    final class TaskDraftValidator {
        var rules: [any TaskDraftRule]

        init(rules: [any TaskDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskDraft]) -> [String: [String]] {
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

    static func defaultTaskDraftValidator() -> TaskDraftValidator {
        return TaskDraftValidator(
            rules: [
                TaskDraftUpdatedAtRangeRule(min: 255, max: 1000),
                TaskDraftReviewerLengthRule(maxLength: 80),
                TaskDraftAllowedLabelRule(allowed: ["rolling"]),
                TaskDraftCodeLengthRule(maxLength: 1000),
                TaskDraftLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
