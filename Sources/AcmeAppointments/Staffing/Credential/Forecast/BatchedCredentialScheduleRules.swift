import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched credential schedule must pass. Check returns its problems, or none.
    protocol BatchedCredentialScheduleRule {
        func check(_ item: BatchedCredentialSchedule) -> [String]
    }

    final class BatchedCredentialScheduleBudgetRangeRule: BatchedCredentialScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCredentialScheduleRequiredDescriptionRule: BatchedCredentialScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCredentialSchedulePriorityRangeRule: BatchedCredentialScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCredentialScheduleAllowedDescriptionRule: BatchedCredentialScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is not allowed"]
            }
            return []
        }
    }

    final class BatchedCredentialScheduleMaximumRangeRule: BatchedCredentialScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCredentialScheduleLabelLengthRule: BatchedCredentialScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCredentialSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched credential schedule.
    final class BatchedCredentialScheduleValidator {
        var rules: [any BatchedCredentialScheduleRule]

        init(rules: [any BatchedCredentialScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCredentialSchedule) -> [String] {
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

        func requireValid(_ item: BatchedCredentialSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCredentialSchedule]) -> [String: [String]] {
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

    static func defaultBatchedCredentialScheduleValidator() -> BatchedCredentialScheduleValidator {
        return BatchedCredentialScheduleValidator(
            rules: [
                BatchedCredentialScheduleBudgetRangeRule(min: 4.9, max: 2618.4),
                BatchedCredentialScheduleRequiredDescriptionRule(
                    message: "batched credential schedule needs this field"
                ),
                BatchedCredentialSchedulePriorityRangeRule(min: 16, max: 80),
                BatchedCredentialScheduleAllowedDescriptionRule(allowed: ["strict", "global"]),
                BatchedCredentialScheduleMaximumRangeRule(min: 7.6, max: 4079.5),
                BatchedCredentialScheduleLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
