import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier ledger must pass. Check returns its problems, or none.
    protocol CourierLedgerRule {
        func check(_ item: CourierLedger) -> [String]
    }

    final class CourierLedgerAllowedProcedureCodeRule: CourierLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is stale"]
            }
            return []
        }
    }

    final class CourierLedgerRequiredTitleRule: CourierLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierLedgerCodePrefixRule: CourierLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierLedgerMarginRangeRule: CourierLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierLedger) -> [String] {
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

    /// Runs every rule of a courier ledger.
    final class CourierLedgerValidator {
        var rules: [any CourierLedgerRule]

        init(rules: [any CourierLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierLedger]) -> [String: [String]] {
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

    static func defaultCourierLedgerValidator() -> CourierLedgerValidator {
        return CourierLedgerValidator(
            rules: [
                CourierLedgerAllowedProcedureCodeRule(allowed: ["legacy", "weighted"]),
                CourierLedgerRequiredTitleRule(message: "courier ledger needs this field"),
                CourierLedgerCodePrefixRule(prefix: "REF"),
                CourierLedgerMarginRangeRule(min: 5.9, max: 2089.7),
            ]
        )
    }
}
