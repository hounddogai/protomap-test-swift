import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched risk score ledger must pass. Check returns its problems, or none.
    protocol BatchedRiskScoreLedgerRule {
        func check(_ item: BatchedRiskScoreLedger) -> [String]
    }

    final class BatchedRiskScoreLedgerRequiredCodeRule: BatchedRiskScoreLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRiskScoreLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRiskScoreLedgerAllowedLabelRule: BatchedRiskScoreLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRiskScoreLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class BatchedRiskScoreLedgerCodeLengthRule: BatchedRiskScoreLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRiskScoreLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRiskScoreLedgerCodePrefixRule: BatchedRiskScoreLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedRiskScoreLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedRiskScoreLedgerCopayRangeRule: BatchedRiskScoreLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRiskScoreLedger) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched risk score ledger.
    final class BatchedRiskScoreLedgerValidator {
        var rules: [any BatchedRiskScoreLedgerRule]

        init(rules: [any BatchedRiskScoreLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRiskScoreLedger) -> [String] {
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

        func requireValid(_ item: BatchedRiskScoreLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRiskScoreLedger]) -> [String: [String]] {
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

    static func defaultBatchedRiskScoreLedgerValidator() -> BatchedRiskScoreLedgerValidator {
        return BatchedRiskScoreLedgerValidator(
            rules: [
                BatchedRiskScoreLedgerRequiredCodeRule(message: "batched risk score ledger needs this field"),
                BatchedRiskScoreLedgerAllowedLabelRule(allowed: ["lenient", "adaptive"]),
                BatchedRiskScoreLedgerCodeLengthRule(maxLength: 80),
                BatchedRiskScoreLedgerCodePrefixRule(prefix: "ACM"),
                BatchedRiskScoreLedgerCopayRangeRule(min: 9.8, max: 4226.1),
            ]
        )
    }
}
