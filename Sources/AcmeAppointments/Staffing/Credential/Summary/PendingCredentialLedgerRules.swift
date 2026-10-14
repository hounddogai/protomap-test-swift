import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending credential ledger must pass. Check returns its problems, or none.
    protocol PendingCredentialLedgerRule {
        func check(_ item: PendingCredentialLedger) -> [String]
    }

    final class PendingCredentialLedgerCodeLengthRule: PendingCredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialLedgerAllowedNameRule: PendingCredentialLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCredentialLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class PendingCredentialLedgerPhoneLengthRule: PendingCredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialLedger) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending credential ledger.
    final class PendingCredentialLedgerValidator {
        var rules: [any PendingCredentialLedgerRule]

        init(rules: [any PendingCredentialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCredentialLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCredentialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCredentialLedger]) -> [String: [String]] {
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

    static func defaultPendingCredentialLedgerValidator() -> PendingCredentialLedgerValidator {
        return PendingCredentialLedgerValidator(
            rules: [
                PendingCredentialLedgerCodeLengthRule(maxLength: 3600),
                PendingCredentialLedgerAllowedNameRule(allowed: []),
                PendingCredentialLedgerPhoneLengthRule(maxLength: 86400),
            ]
        )
    }
}
