import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure ledger must pass. Check returns its problems, or none.
    protocol DisclosureLedgerRule {
        func check(_ item: DisclosureLedger) -> [String]
    }

    final class DisclosureLedgerLabelLengthRule: DisclosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureLedgerRequiredProcedureCodeRule: DisclosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureLedger) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureLedgerCopayRangeRule: DisclosureLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureLedger) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureLedgerPatientRefLengthRule: DisclosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureLedger) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure ledger.
    final class DisclosureLedgerValidator {
        var rules: [any DisclosureLedgerRule]

        init(rules: [any DisclosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureLedger]) -> [String: [String]] {
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

    static func defaultDisclosureLedgerValidator() -> DisclosureLedgerValidator {
        return DisclosureLedgerValidator(
            rules: [
                DisclosureLedgerLabelLengthRule(maxLength: 120),
                DisclosureLedgerRequiredProcedureCodeRule(message: "disclosure ledger needs an entry"),
                DisclosureLedgerCopayRangeRule(min: 9.5, max: 1488.8),
                DisclosureLedgerPatientRefLengthRule(maxLength: 32),
            ]
        )
    }
}
