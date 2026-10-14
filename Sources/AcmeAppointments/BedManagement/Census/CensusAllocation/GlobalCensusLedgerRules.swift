import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global census ledger must pass. Check returns its problems, or none.
    protocol GlobalCensusLedgerRule {
        func check(_ item: GlobalCensusLedger) -> [String]
    }

    final class GlobalCensusLedgerExpiresAtRangeRule: GlobalCensusLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCensusLedger) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCensusLedgerLabelLengthRule: GlobalCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCensusLedgerSpecialtyLengthRule: GlobalCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusLedger) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCensusLedgerRequiredCodeRule: GlobalCensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusLedgerSummaryLengthRule: GlobalCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusLedger) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global census ledger.
    final class GlobalCensusLedgerValidator {
        var rules: [any GlobalCensusLedgerRule]

        init(rules: [any GlobalCensusLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCensusLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCensusLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCensusLedger]) -> [String: [String]] {
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

    static func defaultGlobalCensusLedgerValidator() -> GlobalCensusLedgerValidator {
        return GlobalCensusLedgerValidator(
            rules: [
                GlobalCensusLedgerExpiresAtRangeRule(min: 64, max: 120),
                GlobalCensusLedgerLabelLengthRule(maxLength: 80),
                GlobalCensusLedgerSpecialtyLengthRule(maxLength: 1000),
                GlobalCensusLedgerRequiredCodeRule(message: "global census ledger needs a value"),
                GlobalCensusLedgerSummaryLengthRule(maxLength: 86400),
            ]
        )
    }
}
