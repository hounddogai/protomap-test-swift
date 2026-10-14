import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score ledger must pass. Check returns its problems, or none.
    protocol RiskScoreLedgerRule {
        func check(_ item: RiskScoreLedger) -> [String]
    }

    final class RiskScoreLedgerRequiredCodeRule: RiskScoreLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreLedgerLabelLengthRule: RiskScoreLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreLedgerCurrencyLengthRule: RiskScoreLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreLedger) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreLedgerRequiredLabelRule: RiskScoreLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score ledger.
    final class RiskScoreLedgerValidator {
        var rules: [any RiskScoreLedgerRule]

        init(rules: [any RiskScoreLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreLedger]) -> [String: [String]] {
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

    static func defaultRiskScoreLedgerValidator() -> RiskScoreLedgerValidator {
        return RiskScoreLedgerValidator(
            rules: [
                RiskScoreLedgerRequiredCodeRule(message: "risk score ledger needs this field"),
                RiskScoreLedgerLabelLengthRule(maxLength: 3600),
                RiskScoreLedgerCurrencyLengthRule(maxLength: 120),
                RiskScoreLedgerRequiredLabelRule(message: "risk score ledger needs an entry"),
            ]
        )
    }
}
