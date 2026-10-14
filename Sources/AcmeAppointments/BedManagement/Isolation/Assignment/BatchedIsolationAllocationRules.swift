import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched isolation allocation must pass. Check returns its problems, or none.
    protocol BatchedIsolationAllocationRule {
        func check(_ item: BatchedIsolationAllocation) -> [String]
    }

    final class BatchedIsolationAllocationRequiredLabelRule: BatchedIsolationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedIsolationAllocationRequiredDiagnosisCodeRule: BatchedIsolationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedIsolationAllocationScoreRangeRule: BatchedIsolationAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedIsolationAllocationMinimumRangeRule: BatchedIsolationAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedIsolationAllocationCodeLengthRule: BatchedIsolationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedIsolationAllocationAttemptsRangeRule: BatchedIsolationAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedIsolationAllocation) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched isolation allocation.
    final class BatchedIsolationAllocationValidator {
        var rules: [any BatchedIsolationAllocationRule]

        init(rules: [any BatchedIsolationAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedIsolationAllocation) -> [String] {
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

        func requireValid(_ item: BatchedIsolationAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedIsolationAllocation]) -> [String: [String]] {
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

    static func defaultBatchedIsolationAllocationValidator() -> BatchedIsolationAllocationValidator {
        return BatchedIsolationAllocationValidator(
            rules: [
                BatchedIsolationAllocationRequiredLabelRule(message: "batched isolation allocation needs this field"),
                BatchedIsolationAllocationRequiredDiagnosisCodeRule(
                    message: "batched isolation allocation needs an entry"
                ),
                BatchedIsolationAllocationScoreRangeRule(min: 2.9, max: 1636.5),
                BatchedIsolationAllocationMinimumRangeRule(min: 6.0, max: 4244.9),
                BatchedIsolationAllocationCodeLengthRule(maxLength: 64),
                BatchedIsolationAllocationAttemptsRangeRule(min: 64, max: 80),
            ]
        )
    }
}
