import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession ledger must pass. Check returns its problems, or none.
    protocol AccessionLedgerRule {
        func check(_ item: AccessionLedger) -> [String]
    }

    final class AccessionLedgerProcedureCodeLengthRule: AccessionLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionLedger) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionLedgerCodePrefixRule: AccessionLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionLedgerNameLengthRule: AccessionLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionLedgerRequiredProcedureCodeRule: AccessionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionLedger) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionLedgerBudgetRangeRule: AccessionLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionLedger) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionLedgerCodeLengthRule: AccessionLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession ledger.
    final class AccessionLedgerValidator {
        var rules: [any AccessionLedgerRule]

        init(rules: [any AccessionLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionLedger) -> [String] {
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

        func requireValid(_ item: AccessionLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionLedger]) -> [String: [String]] {
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

    static func defaultAccessionLedgerValidator() -> AccessionLedgerValidator {
        return AccessionLedgerValidator(
            rules: [
                AccessionLedgerProcedureCodeLengthRule(maxLength: 32),
                AccessionLedgerCodePrefixRule(prefix: "ACM"),
                AccessionLedgerNameLengthRule(maxLength: 80),
                AccessionLedgerRequiredProcedureCodeRule(message: "accession ledger needs a value"),
                AccessionLedgerBudgetRangeRule(min: 3.0, max: 378.0),
                AccessionLedgerCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
