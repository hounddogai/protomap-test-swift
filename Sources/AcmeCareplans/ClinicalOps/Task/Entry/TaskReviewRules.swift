import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task review must pass. Check returns its problems, or none.
    protocol TaskReviewRule {
        func check(_ item: TaskReview) -> [String]
    }

    final class TaskReviewRequiredOwnerIDRule: TaskReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskReviewCodeLengthRule: TaskReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskReviewRequiredCodeRule: TaskReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskReviewRequiredNameRule: TaskReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task review.
    final class TaskReviewValidator {
        var rules: [any TaskReviewRule]

        init(rules: [any TaskReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskReview) -> [String] {
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

        func requireValid(_ item: TaskReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskReview]) -> [String: [String]] {
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

    static func defaultTaskReviewValidator() -> TaskReviewValidator {
        return TaskReviewValidator(
            rules: [
                TaskReviewRequiredOwnerIDRule(message: "task review needs an entry"),
                TaskReviewCodeLengthRule(maxLength: 16),
                TaskReviewRequiredCodeRule(message: "task review needs a value"),
                TaskReviewRequiredNameRule(message: "task review needs this field"),
            ]
        )
    }
}
