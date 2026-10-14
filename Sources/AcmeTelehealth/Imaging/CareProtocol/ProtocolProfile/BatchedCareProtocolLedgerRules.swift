import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched care protocol ledger must pass. Check returns its problems, or none.
    protocol BatchedCareProtocolLedgerRule {
        func check(_ item: BatchedCareProtocolLedger) -> [String]
    }

    final class BatchedCareProtocolLedgerVersionRangeRule: BatchedCareProtocolLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolLedger) -> [String] {
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

    final class BatchedCareProtocolLedgerActiveGuardRule: BatchedCareProtocolLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedCareProtocolLedger) -> [String] {
            if item.active && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class BatchedCareProtocolLedgerOwnerIDLengthRule: BatchedCareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareProtocolLedger) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolLedgerCodeLengthRule: BatchedCareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareProtocolLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolLedgerAllowedLabelRule: BatchedCareProtocolLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCareProtocolLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a batched care protocol ledger.
    final class BatchedCareProtocolLedgerValidator {
        var rules: [any BatchedCareProtocolLedgerRule]

        init(rules: [any BatchedCareProtocolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareProtocolLedger) -> [String] {
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

        func requireValid(_ item: BatchedCareProtocolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareProtocolLedger]) -> [String: [String]] {
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

    static func defaultBatchedCareProtocolLedgerValidator() -> BatchedCareProtocolLedgerValidator {
        return BatchedCareProtocolLedgerValidator(
            rules: [
                BatchedCareProtocolLedgerVersionRangeRule(min: 3600, max: 86400),
                BatchedCareProtocolLedgerActiveGuardRule(limit: 2.5),
                BatchedCareProtocolLedgerOwnerIDLengthRule(maxLength: 16),
                BatchedCareProtocolLedgerCodeLengthRule(maxLength: 80),
                BatchedCareProtocolLedgerAllowedLabelRule(allowed: []),
            ]
        )
    }
}
