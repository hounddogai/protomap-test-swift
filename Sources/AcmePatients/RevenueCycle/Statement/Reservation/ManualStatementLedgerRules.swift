import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual statement ledger must pass. Check returns its problems, or none.
    protocol ManualStatementLedgerRule {
        func check(_ item: ManualStatementLedger) -> [String]
    }

    final class ManualStatementLedgerRequiredNameRule: ManualStatementLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualStatementLedgerSpecialtyLengthRule: ManualStatementLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualStatementLedgerRequiredCodeRule: ManualStatementLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualStatementLedgerAllowedContactEmailRule: ManualStatementLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is expired"]
            }
            return []
        }
    }

    final class ManualStatementLedgerNameLengthRule: ManualStatementLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualStatementLedgerCeilingRangeRule: ManualStatementLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualStatementLedger) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual statement ledger.
    final class ManualStatementLedgerValidator {
        var rules: [any ManualStatementLedgerRule]

        init(rules: [any ManualStatementLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualStatementLedger) -> [String] {
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

        func requireValid(_ item: ManualStatementLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualStatementLedger]) -> [String: [String]] {
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

    static func defaultManualStatementLedgerValidator() -> ManualStatementLedgerValidator {
        return ManualStatementLedgerValidator(
            rules: [
                ManualStatementLedgerRequiredNameRule(message: "manual statement ledger needs this field"),
                ManualStatementLedgerSpecialtyLengthRule(maxLength: 3600),
                ManualStatementLedgerRequiredCodeRule(message: "manual statement ledger needs an entry"),
                ManualStatementLedgerAllowedContactEmailRule(allowed: ["scheduled", "primary"]),
                ManualStatementLedgerNameLengthRule(maxLength: 80),
                ManualStatementLedgerCeilingRangeRule(min: 6.3, max: 1830.3),
            ]
        )
    }
}
