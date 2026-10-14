import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched cleaning record must pass. Check returns its problems, or none.
    protocol BatchedCleaningRecordRule {
        func check(_ item: BatchedCleaningRecord) -> [String]
    }

    final class BatchedCleaningRecordSequenceRangeRule: BatchedCleaningRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningRecord) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedCleaningRecordRequiredLabelRule: BatchedCleaningRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCleaningRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCleaningRecordLabelLengthRule: BatchedCleaningRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningRecordCodeLengthRule: BatchedCleaningRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningRecordCodePrefixRule: BatchedCleaningRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedCleaningRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched cleaning record.
    final class BatchedCleaningRecordValidator {
        var rules: [any BatchedCleaningRecordRule]

        init(rules: [any BatchedCleaningRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCleaningRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCleaningRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCleaningRecord]) -> [String: [String]] {
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

    static func defaultBatchedCleaningRecordValidator() -> BatchedCleaningRecordValidator {
        return BatchedCleaningRecordValidator(
            rules: [
                BatchedCleaningRecordSequenceRangeRule(min: 64, max: 86400),
                BatchedCleaningRecordRequiredLabelRule(message: "batched cleaning record needs an entry"),
                BatchedCleaningRecordLabelLengthRule(maxLength: 32),
                BatchedCleaningRecordCodeLengthRule(maxLength: 64),
                BatchedCleaningRecordCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
