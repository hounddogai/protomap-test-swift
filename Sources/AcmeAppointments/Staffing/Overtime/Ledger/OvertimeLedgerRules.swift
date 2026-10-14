import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime ledger must pass. Check returns its problems, or none.
    protocol OvertimeLedgerRule {
        func check(_ item: OvertimeLedger) -> [String]
    }

    final class OvertimeLedgerRequiredCodeRule: OvertimeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeLedgerRequiredTitleRule: OvertimeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeLedgerRequiredUnitRule: OvertimeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeLedger) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeLedgerUnitLengthRule: OvertimeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeLedger) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeLedgerAllowedUnitRule: OvertimeLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime ledger.
    final class OvertimeLedgerValidator {
        var rules: [any OvertimeLedgerRule]

        init(rules: [any OvertimeLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeLedger]) -> [String: [String]] {
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

    static func defaultOvertimeLedgerValidator() -> OvertimeLedgerValidator {
        return OvertimeLedgerValidator(
            rules: [
                OvertimeLedgerRequiredCodeRule(message: "overtime ledger needs a value"),
                OvertimeLedgerRequiredTitleRule(message: "overtime ledger needs a value"),
                OvertimeLedgerRequiredUnitRule(message: "overtime ledger needs this field"),
                OvertimeLedgerUnitLengthRule(maxLength: 80),
                OvertimeLedgerAllowedUnitRule(allowed: ["batched", "fallback", "adaptive"]),
            ]
        )
    }
}
