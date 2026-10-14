import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict inventory ledger must pass. Check returns its problems, or none.
    protocol StrictInventoryLedgerRule {
        func check(_ item: StrictInventoryLedger) -> [String]
    }

    final class StrictInventoryLedgerAllowedCodeRule: StrictInventoryLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class StrictInventoryLedgerCodePrefixRule: StrictInventoryLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictInventoryLedgerRequiredPatientRefRule: StrictInventoryLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInventoryLedgerRequiredTitleRule: StrictInventoryLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInventoryLedgerBatchSizeRangeRule: StrictInventoryLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictInventoryLedgerCodeLengthRule: StrictInventoryLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictInventoryLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict inventory ledger.
    final class StrictInventoryLedgerValidator {
        var rules: [any StrictInventoryLedgerRule]

        init(rules: [any StrictInventoryLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictInventoryLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictInventoryLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictInventoryLedger]) -> [String: [String]] {
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

    static func defaultStrictInventoryLedgerValidator() -> StrictInventoryLedgerValidator {
        return StrictInventoryLedgerValidator(
            rules: [
                StrictInventoryLedgerAllowedCodeRule(allowed: ["fallback", "scheduled", "rolling"]),
                StrictInventoryLedgerCodePrefixRule(prefix: "Q"),
                StrictInventoryLedgerRequiredPatientRefRule(message: "strict inventory ledger needs this field"),
                StrictInventoryLedgerRequiredTitleRule(message: "strict inventory ledger needs this field"),
                StrictInventoryLedgerBatchSizeRangeRule(min: 255, max: 86400),
                StrictInventoryLedgerCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
