import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled language ledger must pass. Check returns its problems, or none.
    protocol ScheduledLanguageLedgerRule {
        func check(_ item: ScheduledLanguageLedger) -> [String]
    }

    final class ScheduledLanguageLedgerAllowedCodeRule: ScheduledLanguageLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledLanguageLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class ScheduledLanguageLedgerCodeLengthRule: ScheduledLanguageLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageLedgerApprovedGuardRule: ScheduledLanguageLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ScheduledLanguageLedger) -> [String] {
            if item.approved && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ScheduledLanguageLedgerCodePrefixRule: ScheduledLanguageLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledLanguageLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledLanguageLedgerMarginRangeRule: ScheduledLanguageLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledLanguageLedger) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled language ledger.
    final class ScheduledLanguageLedgerValidator {
        var rules: [any ScheduledLanguageLedgerRule]

        init(rules: [any ScheduledLanguageLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledLanguageLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledLanguageLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledLanguageLedger]) -> [String: [String]] {
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

    static func defaultScheduledLanguageLedgerValidator() -> ScheduledLanguageLedgerValidator {
        return ScheduledLanguageLedgerValidator(
            rules: [
                ScheduledLanguageLedgerAllowedCodeRule(allowed: ["pending"]),
                ScheduledLanguageLedgerCodeLengthRule(maxLength: 32),
                ScheduledLanguageLedgerApprovedGuardRule(limit: 8.9),
                ScheduledLanguageLedgerCodePrefixRule(prefix: "X"),
                ScheduledLanguageLedgerMarginRangeRule(min: 3.8, max: 586.5),
            ]
        )
    }
}
