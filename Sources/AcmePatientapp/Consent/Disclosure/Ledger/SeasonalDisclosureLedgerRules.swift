import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal disclosure ledger must pass. Check returns its problems, or none.
    protocol SeasonalDisclosureLedgerRule {
        func check(_ item: SeasonalDisclosureLedger) -> [String]
    }

    final class SeasonalDisclosureLedgerRequiredLabelRule: SeasonalDisclosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDisclosureLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalDisclosureLedgerRateRangeRule: SeasonalDisclosureLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureLedger) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalDisclosureLedgerExpiresAtRangeRule: SeasonalDisclosureLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureLedger) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalDisclosureLedgerCopayRangeRule: SeasonalDisclosureLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDisclosureLedger) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal disclosure ledger.
    final class SeasonalDisclosureLedgerValidator {
        var rules: [any SeasonalDisclosureLedgerRule]

        init(rules: [any SeasonalDisclosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDisclosureLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalDisclosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDisclosureLedger]) -> [String: [String]] {
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

    static func defaultSeasonalDisclosureLedgerValidator() -> SeasonalDisclosureLedgerValidator {
        return SeasonalDisclosureLedgerValidator(
            rules: [
                SeasonalDisclosureLedgerRequiredLabelRule(message: "seasonal disclosure ledger needs this field"),
                SeasonalDisclosureLedgerRateRangeRule(min: 5.6, max: 856.0),
                SeasonalDisclosureLedgerExpiresAtRangeRule(min: 32, max: 32),
                SeasonalDisclosureLedgerCopayRangeRule(min: 8.0, max: 4662.8),
            ]
        )
    }
}
