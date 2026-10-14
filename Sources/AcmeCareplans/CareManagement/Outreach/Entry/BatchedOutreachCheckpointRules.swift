import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched outreach checkpoint must pass. Check returns its problems, or none.
    protocol BatchedOutreachCheckpointRule {
        func check(_ item: BatchedOutreachCheckpoint) -> [String]
    }

    final class BatchedOutreachCheckpointMaximumRangeRule: BatchedOutreachCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedOutreachCheckpointRequiredNameRule: BatchedOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachCheckpointRequiredCodeRule: BatchedOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachCheckpointCodeLengthRule: BatchedOutreachCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOutreachCheckpointRequiredWardRule: BatchedOutreachCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOutreachCheckpointAttemptsRangeRule: BatchedOutreachCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOutreachCheckpoint) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched outreach checkpoint.
    final class BatchedOutreachCheckpointValidator {
        var rules: [any BatchedOutreachCheckpointRule]

        init(rules: [any BatchedOutreachCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOutreachCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOutreachCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOutreachCheckpoint]) -> [String: [String]] {
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

    static func defaultBatchedOutreachCheckpointValidator() -> BatchedOutreachCheckpointValidator {
        return BatchedOutreachCheckpointValidator(
            rules: [
                BatchedOutreachCheckpointMaximumRangeRule(min: 0.6, max: 2103.8),
                BatchedOutreachCheckpointRequiredNameRule(message: "batched outreach checkpoint needs a value"),
                BatchedOutreachCheckpointRequiredCodeRule(message: "batched outreach checkpoint needs a value"),
                BatchedOutreachCheckpointCodeLengthRule(maxLength: 16),
                BatchedOutreachCheckpointRequiredWardRule(message: "batched outreach checkpoint needs this field"),
                BatchedOutreachCheckpointAttemptsRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
