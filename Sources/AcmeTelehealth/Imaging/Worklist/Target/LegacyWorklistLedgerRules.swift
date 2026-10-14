import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy worklist ledger must pass. Check returns its problems, or none.
    protocol LegacyWorklistLedgerRule {
        func check(_ item: LegacyWorklistLedger) -> [String]
    }

    final class LegacyWorklistLedgerRateRangeRule: LegacyWorklistLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
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

    final class LegacyWorklistLedgerRequiredLabelRule: LegacyWorklistLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyWorklistLedgerCategoryLengthRule: LegacyWorklistLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyWorklistLedgerAllowedFacilityRule: LegacyWorklistLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is expired"]
            }
            return []
        }
    }

    final class LegacyWorklistLedgerRequiredCategoryRule: LegacyWorklistLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyWorklistLedgerRequiredCodeRule: LegacyWorklistLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWorklistLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy worklist ledger.
    final class LegacyWorklistLedgerValidator {
        var rules: [any LegacyWorklistLedgerRule]

        init(rules: [any LegacyWorklistLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyWorklistLedger) -> [String] {
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

        func requireValid(_ item: LegacyWorklistLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyWorklistLedger]) -> [String: [String]] {
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

    static func defaultLegacyWorklistLedgerValidator() -> LegacyWorklistLedgerValidator {
        return LegacyWorklistLedgerValidator(
            rules: [
                LegacyWorklistLedgerRateRangeRule(min: 8.8, max: 3303.6),
                LegacyWorklistLedgerRequiredLabelRule(message: "legacy worklist ledger needs a value"),
                LegacyWorklistLedgerCategoryLengthRule(maxLength: 1000),
                LegacyWorklistLedgerAllowedFacilityRule(allowed: ["regional"]),
                LegacyWorklistLedgerRequiredCategoryRule(message: "legacy worklist ledger needs an entry"),
                LegacyWorklistLedgerRequiredCodeRule(message: "legacy worklist ledger needs this field"),
            ]
        )
    }
}
