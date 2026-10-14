import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled task review must pass. Check returns its problems, or none.
    protocol ScheduledTaskReviewRule {
        func check(_ item: ScheduledTaskReview) -> [String]
    }

    final class ScheduledTaskReviewRequiredCodeRule: ScheduledTaskReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledTaskReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledTaskReviewLabelLengthRule: ScheduledTaskReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskReviewDescriptionLengthRule: ScheduledTaskReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskReviewCodeLengthRule: ScheduledTaskReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledTaskReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledTaskReviewSequenceRangeRule: ScheduledTaskReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledTaskReview) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled task review.
    final class ScheduledTaskReviewValidator {
        var rules: [any ScheduledTaskReviewRule]

        init(rules: [any ScheduledTaskReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledTaskReview) -> [String] {
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

        func requireValid(_ item: ScheduledTaskReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledTaskReview]) -> [String: [String]] {
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

    static func defaultScheduledTaskReviewValidator() -> ScheduledTaskReviewValidator {
        return ScheduledTaskReviewValidator(
            rules: [
                ScheduledTaskReviewRequiredCodeRule(message: "scheduled task review needs this field"),
                ScheduledTaskReviewLabelLengthRule(maxLength: 120),
                ScheduledTaskReviewDescriptionLengthRule(maxLength: 120),
                ScheduledTaskReviewCodeLengthRule(maxLength: 64),
                ScheduledTaskReviewSequenceRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
