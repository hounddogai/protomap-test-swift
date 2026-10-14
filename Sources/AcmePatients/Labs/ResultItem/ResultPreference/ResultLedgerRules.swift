import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result ledger must pass. Check returns its problems, or none.
    protocol ResultLedgerRule {
        func check(_ item: ResultLedger) -> [String]
    }

    final class ResultLedgerAmountRangeRule: ResultLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultLedger) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultLedgerCodeLengthRule: ResultLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultLedgerCodePrefixRule: ResultLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultLedgerAllowedNameRule: ResultLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class ResultLedgerChannelLengthRule: ResultLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultLedger) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultLedgerRequiredChannelRule: ResultLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultLedger) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result ledger.
    final class ResultLedgerValidator {
        var rules: [any ResultLedgerRule]

        init(rules: [any ResultLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultLedger]) -> [String: [String]] {
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

    static func defaultResultLedgerValidator() -> ResultLedgerValidator {
        return ResultLedgerValidator(
            rules: [
                ResultLedgerAmountRangeRule(min: 2.4, max: 597.2),
                ResultLedgerCodeLengthRule(maxLength: 64),
                ResultLedgerCodePrefixRule(prefix: "ACM"),
                ResultLedgerAllowedNameRule(allowed: []),
                ResultLedgerChannelLengthRule(maxLength: 32),
                ResultLedgerRequiredChannelRule(message: "result ledger needs this field"),
            ]
        )
    }
}
