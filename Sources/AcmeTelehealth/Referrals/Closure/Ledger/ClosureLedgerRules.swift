import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure ledger must pass. Check returns its problems, or none.
    protocol ClosureLedgerRule {
        func check(_ item: ClosureLedger) -> [String]
    }

    final class ClosureLedgerChannelLengthRule: ClosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureLedger) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureLedgerRequiredChannelRule: ClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureLedger) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureLedgerApprovedGuardRule: ClosureLedgerRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClosureLedger) -> [String] {
            if item.approved && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ClosureLedgerCodeLengthRule: ClosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureLedgerAttemptsRangeRule: ClosureLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureLedger) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureLedgerCodePrefixRule: ClosureLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure ledger.
    final class ClosureLedgerValidator {
        var rules: [any ClosureLedgerRule]

        init(rules: [any ClosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureLedger]) -> [String: [String]] {
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

    static func defaultClosureLedgerValidator() -> ClosureLedgerValidator {
        return ClosureLedgerValidator(
            rules: [
                ClosureLedgerChannelLengthRule(maxLength: 32),
                ClosureLedgerRequiredChannelRule(message: "closure ledger needs an entry"),
                ClosureLedgerApprovedGuardRule(limit: 1000),
                ClosureLedgerCodeLengthRule(maxLength: 1000),
                ClosureLedgerAttemptsRangeRule(min: 16, max: 255),
                ClosureLedgerCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
