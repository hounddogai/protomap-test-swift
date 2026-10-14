import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched witness adjustment must pass. Check returns its problems, or none.
    protocol BatchedWitnessAdjustmentRule {
        func check(_ item: BatchedWitnessAdjustment) -> [String]
    }

    final class BatchedWitnessAdjustmentCodePrefixRule: BatchedWitnessAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedWitnessAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedWitnessAdjustmentUnitLengthRule: BatchedWitnessAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessAdjustment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedWitnessAdjustmentRequiredCodeRule: BatchedWitnessAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessAdjustmentGraceDaysRangeRule: BatchedWitnessAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedWitnessAdjustment) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched witness adjustment.
    final class BatchedWitnessAdjustmentValidator {
        var rules: [any BatchedWitnessAdjustmentRule]

        init(rules: [any BatchedWitnessAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedWitnessAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedWitnessAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedWitnessAdjustment]) -> [String: [String]] {
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

    static func defaultBatchedWitnessAdjustmentValidator() -> BatchedWitnessAdjustmentValidator {
        return BatchedWitnessAdjustmentValidator(
            rules: [
                BatchedWitnessAdjustmentCodePrefixRule(prefix: "OPS"),
                BatchedWitnessAdjustmentUnitLengthRule(maxLength: 255),
                BatchedWitnessAdjustmentRequiredCodeRule(message: "batched witness adjustment needs a value"),
                BatchedWitnessAdjustmentGraceDaysRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
