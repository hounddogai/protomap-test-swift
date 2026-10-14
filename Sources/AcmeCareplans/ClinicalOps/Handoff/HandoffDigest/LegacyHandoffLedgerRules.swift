import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy handoff ledger must pass. Check returns its problems, or none.
    protocol LegacyHandoffLedgerRule {
        func check(_ item: LegacyHandoffLedger) -> [String]
    }

    final class LegacyHandoffLedgerSpecialtyLengthRule: LegacyHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyHandoffLedger) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyHandoffLedgerLabelLengthRule: LegacyHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyHandoffLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyHandoffLedgerAllowedDiagnosisCodeRule: LegacyHandoffLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyHandoffLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is duplicated"]
            }
            return []
        }
    }

    final class LegacyHandoffLedgerDiagnosisCodeLengthRule: LegacyHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyHandoffLedger) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy handoff ledger.
    final class LegacyHandoffLedgerValidator {
        var rules: [any LegacyHandoffLedgerRule]

        init(rules: [any LegacyHandoffLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyHandoffLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyHandoffLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyHandoffLedger]) -> [String: [String]] {
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

    static func defaultLegacyHandoffLedgerValidator() -> LegacyHandoffLedgerValidator {
        return LegacyHandoffLedgerValidator(
            rules: [
                LegacyHandoffLedgerSpecialtyLengthRule(maxLength: 1000),
                LegacyHandoffLedgerLabelLengthRule(maxLength: 120),
                LegacyHandoffLedgerAllowedDiagnosisCodeRule(allowed: ["primary", "rolling"]),
                LegacyHandoffLedgerDiagnosisCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
