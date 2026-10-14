import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot record must pass. Check returns its problems, or none.
    protocol BatchedSlotRecordRule {
        func check(_ item: BatchedSlotRecord) -> [String]
    }

    final class BatchedSlotRecordCodeLengthRule: BatchedSlotRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotRecordAllowedTimezoneRule: BatchedSlotRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedSlotRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is below minimum"]
            }
            return []
        }
    }

    final class BatchedSlotRecordRequiredTitleRule: BatchedSlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot record.
    final class BatchedSlotRecordValidator {
        var rules: [any BatchedSlotRecordRule]

        init(rules: [any BatchedSlotRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSlotRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotRecord]) -> [String: [String]] {
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

    static func defaultBatchedSlotRecordValidator() -> BatchedSlotRecordValidator {
        return BatchedSlotRecordValidator(
            rules: [
                BatchedSlotRecordCodeLengthRule(maxLength: 1000),
                BatchedSlotRecordAllowedTimezoneRule(allowed: ["primary", "default", "rolling"]),
                BatchedSlotRecordRequiredTitleRule(message: "batched slot record needs a value"),
            ]
        )
    }
}
