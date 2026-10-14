import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement entry must pass. Check returns its problems, or none.
    protocol StatementEntryRule {
        func check(_ item: StatementEntry) -> [String]
    }

    final class StatementEntryPhoneLengthRule: StatementEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementEntry) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementEntryCodePrefixRule: StatementEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementEntryRequiredCodeRule: StatementEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementEntryRetriesRangeRule: StatementEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementEntry) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementEntryCodeLengthRule: StatementEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementEntryBudgetRangeRule: StatementEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementEntry) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement entry.
    final class StatementEntryValidator {
        var rules: [any StatementEntryRule]

        init(rules: [any StatementEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementEntry) -> [String] {
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

        func requireValid(_ item: StatementEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementEntry]) -> [String: [String]] {
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

    static func defaultStatementEntryValidator() -> StatementEntryValidator {
        return StatementEntryValidator(
            rules: [
                StatementEntryPhoneLengthRule(maxLength: 255),
                StatementEntryCodePrefixRule(prefix: "X"),
                StatementEntryRequiredCodeRule(message: "statement entry needs a value"),
                StatementEntryRetriesRangeRule(min: 255, max: 3600),
                StatementEntryCodeLengthRule(maxLength: 255),
                StatementEntryBudgetRangeRule(min: 6.2, max: 357.0),
            ]
        )
    }
}
