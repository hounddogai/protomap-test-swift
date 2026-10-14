import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default statement ledger must pass. Check returns its problems, or none.
    protocol DefaultStatementLedgerRule {
        func check(_ item: DefaultStatementLedger) -> [String]
    }

    final class DefaultStatementLedgerExternalRefLengthRule: DefaultStatementLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultStatementLedgerCodeLengthRule: DefaultStatementLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultStatementLedgerRequiredNameRule: DefaultStatementLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultStatementLedgerTitleLengthRule: DefaultStatementLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultStatementLedgerRequiredTitleRule: DefaultStatementLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultStatementLedgerAllowedCodeRule: DefaultStatementLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultStatementLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a default statement ledger.
    final class DefaultStatementLedgerValidator {
        var rules: [any DefaultStatementLedgerRule]

        init(rules: [any DefaultStatementLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultStatementLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultStatementLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultStatementLedger]) -> [String: [String]] {
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

    static func defaultDefaultStatementLedgerValidator() -> DefaultStatementLedgerValidator {
        return DefaultStatementLedgerValidator(
            rules: [
                DefaultStatementLedgerExternalRefLengthRule(maxLength: 16),
                DefaultStatementLedgerCodeLengthRule(maxLength: 1000),
                DefaultStatementLedgerRequiredNameRule(message: "default statement ledger needs this field"),
                DefaultStatementLedgerTitleLengthRule(maxLength: 3600),
                DefaultStatementLedgerRequiredTitleRule(message: "default statement ledger needs this field"),
                DefaultStatementLedgerAllowedCodeRule(allowed: ["fallback", "strict"]),
            ]
        )
    }
}
