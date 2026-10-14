import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched reference range record must pass. Check returns its problems, or none.
    protocol BatchedReferenceRangeRecordRule {
        func check(_ item: BatchedReferenceRangeRecord) -> [String]
    }

    final class BatchedReferenceRangeRecordApprovedGuardRule: BatchedReferenceRangeRecordRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedReferenceRangeRecord) -> [String] {
            if item.approved && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class BatchedReferenceRangeRecordAllowedCodeRule: BatchedReferenceRangeRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedReferenceRangeRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class BatchedReferenceRangeRecordRequiredCodeRule: BatchedReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReferenceRangeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched reference range record.
    final class BatchedReferenceRangeRecordValidator {
        var rules: [any BatchedReferenceRangeRecordRule]

        init(rules: [any BatchedReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReferenceRangeRecord) -> [String] {
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

        func requireValid(_ item: BatchedReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultBatchedReferenceRangeRecordValidator() -> BatchedReferenceRangeRecordValidator {
        return BatchedReferenceRangeRecordValidator(
            rules: [
                BatchedReferenceRangeRecordApprovedGuardRule(limit: 4.2),
                BatchedReferenceRangeRecordAllowedCodeRule(allowed: ["pending", "fallback", "pending"]),
                BatchedReferenceRangeRecordRequiredCodeRule(message: "batched reference range record needs a value"),
            ]
        )
    }
}
