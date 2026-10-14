import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default closure ledger must pass. Check returns its problems, or none.
    protocol DefaultClosureLedgerRule {
        func check(_ item: DefaultClosureLedger) -> [String]
    }

    final class DefaultClosureLedgerBatchSizeRangeRule: DefaultClosureLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultClosureLedgerTitleLengthRule: DefaultClosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultClosureLedgerRequiredPayerRule: DefaultClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultClosureLedgerRequiredTitleRule: DefaultClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultClosureLedgerRequiredReviewerRule: DefaultClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultClosureLedgerAllowedPayerRule: DefaultClosureLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultClosureLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a default closure ledger.
    final class DefaultClosureLedgerValidator {
        var rules: [any DefaultClosureLedgerRule]

        init(rules: [any DefaultClosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClosureLedger) -> [String] {
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

        func requireValid(_ item: DefaultClosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClosureLedger]) -> [String: [String]] {
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

    static func defaultDefaultClosureLedgerValidator() -> DefaultClosureLedgerValidator {
        return DefaultClosureLedgerValidator(
            rules: [
                DefaultClosureLedgerBatchSizeRangeRule(min: 86400, max: 86400),
                DefaultClosureLedgerTitleLengthRule(maxLength: 32),
                DefaultClosureLedgerRequiredPayerRule(message: "default closure ledger needs a value"),
                DefaultClosureLedgerRequiredTitleRule(message: "default closure ledger needs this field"),
                DefaultClosureLedgerRequiredReviewerRule(message: "default closure ledger needs an entry"),
                DefaultClosureLedgerAllowedPayerRule(allowed: ["regional", "default"]),
            ]
        )
    }
}
