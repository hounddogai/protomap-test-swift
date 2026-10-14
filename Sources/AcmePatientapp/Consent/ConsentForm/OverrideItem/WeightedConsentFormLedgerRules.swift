import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted consent form ledger must pass. Check returns its problems, or none.
    protocol WeightedConsentFormLedgerRule {
        func check(_ item: WeightedConsentFormLedger) -> [String]
    }

    final class WeightedConsentFormLedgerCodePrefixRule: WeightedConsentFormLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedConsentFormLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedConsentFormLedgerNameLengthRule: WeightedConsentFormLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedConsentFormLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedConsentFormLedgerBatchSizeRangeRule: WeightedConsentFormLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedConsentFormLedger) -> [String] {
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

    /// Runs every rule of a weighted consent form ledger.
    final class WeightedConsentFormLedgerValidator {
        var rules: [any WeightedConsentFormLedgerRule]

        init(rules: [any WeightedConsentFormLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedConsentFormLedger) -> [String] {
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

        func requireValid(_ item: WeightedConsentFormLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedConsentFormLedger]) -> [String: [String]] {
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

    static func defaultWeightedConsentFormLedgerValidator() -> WeightedConsentFormLedgerValidator {
        return WeightedConsentFormLedgerValidator(
            rules: [
                WeightedConsentFormLedgerCodePrefixRule(prefix: "X"),
                WeightedConsentFormLedgerNameLengthRule(maxLength: 86400),
                WeightedConsentFormLedgerBatchSizeRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
