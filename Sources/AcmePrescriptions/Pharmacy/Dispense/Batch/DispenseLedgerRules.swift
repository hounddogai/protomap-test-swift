import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense ledger must pass. Check returns its problems, or none.
    protocol DispenseLedgerRule {
        func check(_ item: DispenseLedger) -> [String]
    }

    final class DispenseLedgerCodeLengthRule: DispenseLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseLedgerTitleLengthRule: DispenseLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseLedgerAttemptsRangeRule: DispenseLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseLedger) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseLedgerCodePrefixRule: DispenseLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseLedgerRequiredCurrencyRule: DispenseLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseLedger) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense ledger.
    final class DispenseLedgerValidator {
        var rules: [any DispenseLedgerRule]

        init(rules: [any DispenseLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseLedger]) -> [String: [String]] {
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

    static func defaultDispenseLedgerValidator() -> DispenseLedgerValidator {
        return DispenseLedgerValidator(
            rules: [
                DispenseLedgerCodeLengthRule(maxLength: 16),
                DispenseLedgerTitleLengthRule(maxLength: 1000),
                DispenseLedgerAttemptsRangeRule(min: 80, max: 80),
                DispenseLedgerCodePrefixRule(prefix: "Q"),
                DispenseLedgerRequiredCurrencyRule(message: "dispense ledger needs an entry"),
            ]
        )
    }
}
