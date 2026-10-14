import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global panel ledger must pass. Check returns its problems, or none.
    protocol GlobalPanelLedgerRule {
        func check(_ item: GlobalPanelLedger) -> [String]
    }

    final class GlobalPanelLedgerNameLengthRule: GlobalPanelLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPanelLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPanelLedgerContactEmailLengthRule: GlobalPanelLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPanelLedger) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalPanelLedgerMinimumRangeRule: GlobalPanelLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPanelLedger) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalPanelLedgerRequiredCodeRule: GlobalPanelLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPanelLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalPanelLedgerRequiredContactEmailRule: GlobalPanelLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPanelLedger) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global panel ledger.
    final class GlobalPanelLedgerValidator {
        var rules: [any GlobalPanelLedgerRule]

        init(rules: [any GlobalPanelLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPanelLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalPanelLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPanelLedger]) -> [String: [String]] {
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

    static func defaultGlobalPanelLedgerValidator() -> GlobalPanelLedgerValidator {
        return GlobalPanelLedgerValidator(
            rules: [
                GlobalPanelLedgerNameLengthRule(maxLength: 32),
                GlobalPanelLedgerContactEmailLengthRule(maxLength: 80),
                GlobalPanelLedgerMinimumRangeRule(min: 6.0, max: 3572.8),
                GlobalPanelLedgerRequiredCodeRule(message: "global panel ledger needs an entry"),
                GlobalPanelLedgerRequiredContactEmailRule(message: "global panel ledger needs a value"),
            ]
        )
    }
}
