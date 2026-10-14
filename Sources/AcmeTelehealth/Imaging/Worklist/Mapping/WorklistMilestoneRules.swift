import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist milestone must pass. Check returns its problems, or none.
    protocol WorklistMilestoneRule {
        func check(_ item: WorklistMilestone) -> [String]
    }

    final class WorklistMilestoneRequiredTitleRule: WorklistMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistMilestoneRequiredSegmentRule: WorklistMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistMilestone) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistMilestoneTitleLengthRule: WorklistMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistMilestoneNotesLengthRule: WorklistMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistMilestone) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist milestone.
    final class WorklistMilestoneValidator {
        var rules: [any WorklistMilestoneRule]

        init(rules: [any WorklistMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistMilestone]) -> [String: [String]] {
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

    static func defaultWorklistMilestoneValidator() -> WorklistMilestoneValidator {
        return WorklistMilestoneValidator(
            rules: [
                WorklistMilestoneRequiredTitleRule(message: "worklist milestone needs this field"),
                WorklistMilestoneRequiredSegmentRule(message: "worklist milestone needs a value"),
                WorklistMilestoneTitleLengthRule(maxLength: 16),
                WorklistMilestoneNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
