import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language ledger must pass. Check returns its problems, or none.
    protocol LanguageLedgerRule {
        func check(_ item: LanguageLedger) -> [String]
    }

    final class LanguageLedgerRequiredCurrencyRule: LanguageLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageLedger) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageLedgerUpdatedAtRangeRule: LanguageLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageLedger) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageLedgerNameLengthRule: LanguageLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language ledger.
    final class LanguageLedgerValidator {
        var rules: [any LanguageLedgerRule]

        init(rules: [any LanguageLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageLedger]) -> [String: [String]] {
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

    static func defaultLanguageLedgerValidator() -> LanguageLedgerValidator {
        return LanguageLedgerValidator(
            rules: [
                LanguageLedgerRequiredCurrencyRule(message: "language ledger needs a value"),
                LanguageLedgerUpdatedAtRangeRule(min: 16, max: 3600),
                LanguageLedgerNameLengthRule(maxLength: 32),
            ]
        )
    }
}
