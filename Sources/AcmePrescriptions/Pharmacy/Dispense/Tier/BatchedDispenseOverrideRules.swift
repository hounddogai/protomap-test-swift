import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched dispense override must pass. Check returns its problems, or none.
    protocol BatchedDispenseOverrideRule {
        func check(_ item: BatchedDispenseOverride) -> [String]
    }

    final class BatchedDispenseOverrideRequiredNotesRule: BatchedDispenseOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDispenseOverride) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDispenseOverrideNameLengthRule: BatchedDispenseOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDispenseOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDispenseOverrideNotesLengthRule: BatchedDispenseOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDispenseOverride) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDispenseOverrideDosageMgRangeRule: BatchedDispenseOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseOverride) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedDispenseOverrideVersionRangeRule: BatchedDispenseOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseOverride) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched dispense override.
    final class BatchedDispenseOverrideValidator {
        var rules: [any BatchedDispenseOverrideRule]

        init(rules: [any BatchedDispenseOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDispenseOverride) -> [String] {
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

        func requireValid(_ item: BatchedDispenseOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDispenseOverride]) -> [String: [String]] {
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

    static func defaultBatchedDispenseOverrideValidator() -> BatchedDispenseOverrideValidator {
        return BatchedDispenseOverrideValidator(
            rules: [
                BatchedDispenseOverrideRequiredNotesRule(message: "batched dispense override needs this field"),
                BatchedDispenseOverrideNameLengthRule(maxLength: 80),
                BatchedDispenseOverrideNotesLengthRule(maxLength: 120),
                BatchedDispenseOverrideDosageMgRangeRule(min: 7.5, max: 1967.7),
                BatchedDispenseOverrideVersionRangeRule(min: 32, max: 80),
            ]
        )
    }
}
