import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched isolation record must pass. Check returns its problems, or none.
    protocol BatchedIsolationRecordRule {
        func check(_ item: BatchedIsolationRecord) -> [String]
    }

    final class BatchedIsolationRecordDescriptionLengthRule: BatchedIsolationRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedIsolationRecord) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedIsolationRecordOwnerIDLengthRule: BatchedIsolationRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedIsolationRecord) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedIsolationRecordRequiredLabelRule: BatchedIsolationRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedIsolationRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched isolation record.
    final class BatchedIsolationRecordValidator {
        var rules: [any BatchedIsolationRecordRule]

        init(rules: [any BatchedIsolationRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedIsolationRecord) -> [String] {
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

        func requireValid(_ item: BatchedIsolationRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedIsolationRecord]) -> [String: [String]] {
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

    static func defaultBatchedIsolationRecordValidator() -> BatchedIsolationRecordValidator {
        return BatchedIsolationRecordValidator(
            rules: [
                BatchedIsolationRecordDescriptionLengthRule(maxLength: 32),
                BatchedIsolationRecordOwnerIDLengthRule(maxLength: 120),
                BatchedIsolationRecordRequiredLabelRule(message: "batched isolation record needs this field"),
            ]
        )
    }
}
