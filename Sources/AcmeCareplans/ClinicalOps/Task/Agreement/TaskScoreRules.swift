import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task score must pass. Check returns its problems, or none.
    protocol TaskScoreRule {
        func check(_ item: TaskScore) -> [String]
    }

    final class TaskScoreCodeLengthRule: TaskScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskScoreRequiredNameRule: TaskScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskScoreFacilityLengthRule: TaskScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskScore) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskScoreNameLengthRule: TaskScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task score.
    final class TaskScoreValidator {
        var rules: [any TaskScoreRule]

        init(rules: [any TaskScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskScore]) -> [String: [String]] {
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

    static func defaultTaskScoreValidator() -> TaskScoreValidator {
        return TaskScoreValidator(
            rules: [
                TaskScoreCodeLengthRule(maxLength: 3600),
                TaskScoreRequiredNameRule(message: "task score needs this field"),
                TaskScoreFacilityLengthRule(maxLength: 86400),
                TaskScoreNameLengthRule(maxLength: 120),
            ]
        )
    }
}
