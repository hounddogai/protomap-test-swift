import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched study schedule must pass. Check returns its problems, or none.
    protocol BatchedStudyScheduleRule {
        func check(_ item: BatchedStudySchedule) -> [String]
    }

    final class BatchedStudyScheduleRequiredCodeRule: BatchedStudyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStudySchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStudyScheduleReviewerLengthRule: BatchedStudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStudySchedule) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStudyScheduleRequiredLocaleRule: BatchedStudyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStudySchedule) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStudyScheduleCodeLengthRule: BatchedStudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStudySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched study schedule.
    final class BatchedStudyScheduleValidator {
        var rules: [any BatchedStudyScheduleRule]

        init(rules: [any BatchedStudyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStudySchedule) -> [String] {
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

        func requireValid(_ item: BatchedStudySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStudySchedule]) -> [String: [String]] {
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

    static func defaultBatchedStudyScheduleValidator() -> BatchedStudyScheduleValidator {
        return BatchedStudyScheduleValidator(
            rules: [
                BatchedStudyScheduleRequiredCodeRule(message: "batched study schedule needs this field"),
                BatchedStudyScheduleReviewerLengthRule(maxLength: 64),
                BatchedStudyScheduleRequiredLocaleRule(message: "batched study schedule needs an entry"),
                BatchedStudyScheduleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
