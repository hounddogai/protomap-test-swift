import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched task exception must pass. Check returns its problems, or none.
    protocol BatchedTaskExceptionRule {
        func check(_ item: BatchedTaskException) -> [String]
    }

    final class BatchedTaskExceptionRequiredSegmentRule: BatchedTaskExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTaskException) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedTaskExceptionWeightRangeRule: BatchedTaskExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTaskException) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedTaskExceptionAcuityRangeRule: BatchedTaskExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTaskException) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedTaskExceptionCodeLengthRule: BatchedTaskExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedTaskExceptionSegmentLengthRule: BatchedTaskExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskException) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedTaskExceptionCodePrefixRule: BatchedTaskExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedTaskException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched task exception.
    final class BatchedTaskExceptionValidator {
        var rules: [any BatchedTaskExceptionRule]

        init(rules: [any BatchedTaskExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTaskException) -> [String] {
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

        func requireValid(_ item: BatchedTaskException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTaskException]) -> [String: [String]] {
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

    static func defaultBatchedTaskExceptionValidator() -> BatchedTaskExceptionValidator {
        return BatchedTaskExceptionValidator(
            rules: [
                BatchedTaskExceptionRequiredSegmentRule(message: "batched task exception needs this field"),
                BatchedTaskExceptionWeightRangeRule(min: 4.1, max: 1886.2),
                BatchedTaskExceptionAcuityRangeRule(min: 32, max: 3600),
                BatchedTaskExceptionCodeLengthRule(maxLength: 16),
                BatchedTaskExceptionSegmentLengthRule(maxLength: 3600),
                BatchedTaskExceptionCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
