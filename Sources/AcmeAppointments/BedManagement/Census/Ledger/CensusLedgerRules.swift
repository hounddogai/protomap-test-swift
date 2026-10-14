import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census ledger must pass. Check returns its problems, or none.
    protocol CensusLedgerRule {
        func check(_ item: CensusLedger) -> [String]
    }

    final class CensusLedgerMaximumRangeRule: CensusLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusLedger) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusLedgerRequiredCodeRule: CensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusLedgerCodePrefixRule: CensusLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusLedgerDiagnosisCodeLengthRule: CensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusLedger) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusLedgerRequiredDiagnosisCodeRule: CensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusLedger) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census ledger.
    final class CensusLedgerValidator {
        var rules: [any CensusLedgerRule]

        init(rules: [any CensusLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusLedger]) -> [String: [String]] {
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

    static func defaultCensusLedgerValidator() -> CensusLedgerValidator {
        return CensusLedgerValidator(
            rules: [
                CensusLedgerMaximumRangeRule(min: 7.6, max: 2935.3),
                CensusLedgerRequiredCodeRule(message: "census ledger needs this field"),
                CensusLedgerCodePrefixRule(prefix: "ACM"),
                CensusLedgerDiagnosisCodeLengthRule(maxLength: 1000),
                CensusLedgerRequiredDiagnosisCodeRule(message: "census ledger needs this field"),
            ]
        )
    }
}
