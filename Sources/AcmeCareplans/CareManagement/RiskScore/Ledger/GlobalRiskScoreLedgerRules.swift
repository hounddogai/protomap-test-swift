import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global risk score ledger must pass. Check returns its problems, or none.
    protocol GlobalRiskScoreLedgerRule {
        func check(_ item: GlobalRiskScoreLedger) -> [String]
    }

    final class GlobalRiskScoreLedgerRequiredProcedureCodeRule: GlobalRiskScoreLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRiskScoreLedger) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRiskScoreLedgerDosageMgRangeRule: GlobalRiskScoreLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRiskScoreLedger) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalRiskScoreLedgerProcedureCodeLengthRule: GlobalRiskScoreLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRiskScoreLedger) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRiskScoreLedgerAllowedCodeRule: GlobalRiskScoreLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalRiskScoreLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a global risk score ledger.
    final class GlobalRiskScoreLedgerValidator {
        var rules: [any GlobalRiskScoreLedgerRule]

        init(rules: [any GlobalRiskScoreLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRiskScoreLedger) -> [String] {
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

        func requireValid(_ item: GlobalRiskScoreLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRiskScoreLedger]) -> [String: [String]] {
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

    static func defaultGlobalRiskScoreLedgerValidator() -> GlobalRiskScoreLedgerValidator {
        return GlobalRiskScoreLedgerValidator(
            rules: [
                GlobalRiskScoreLedgerRequiredProcedureCodeRule(message: "global risk score ledger needs this field"),
                GlobalRiskScoreLedgerDosageMgRangeRule(min: 7.6, max: 2495.1),
                GlobalRiskScoreLedgerProcedureCodeLengthRule(maxLength: 86400),
                GlobalRiskScoreLedgerAllowedCodeRule(allowed: ["manual", "regional"]),
            ]
        )
    }
}
