import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal language ledger must pass. Check returns its problems, or none.
    protocol SeasonalLanguageLedgerRule {
        func check(_ item: SeasonalLanguageLedger) -> [String]
    }

    final class SeasonalLanguageLedgerRequiredClinicianIDRule: SeasonalLanguageLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalLanguageLedger) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalLanguageLedgerLabelLengthRule: SeasonalLanguageLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalLanguageLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalLanguageLedgerAllowedLabelRule: SeasonalLanguageLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalLanguageLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class SeasonalLanguageLedgerCodeLengthRule: SeasonalLanguageLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalLanguageLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalLanguageLedgerRequiredCodeRule: SeasonalLanguageLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalLanguageLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal language ledger.
    final class SeasonalLanguageLedgerValidator {
        var rules: [any SeasonalLanguageLedgerRule]

        init(rules: [any SeasonalLanguageLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalLanguageLedger) -> [String] {
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

        func requireValid(_ item: SeasonalLanguageLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalLanguageLedger]) -> [String: [String]] {
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

    static func defaultSeasonalLanguageLedgerValidator() -> SeasonalLanguageLedgerValidator {
        return SeasonalLanguageLedgerValidator(
            rules: [
                SeasonalLanguageLedgerRequiredClinicianIDRule(message: "seasonal language ledger needs a value"),
                SeasonalLanguageLedgerLabelLengthRule(maxLength: 120),
                SeasonalLanguageLedgerAllowedLabelRule(allowed: ["capped"]),
                SeasonalLanguageLedgerCodeLengthRule(maxLength: 86400),
                SeasonalLanguageLedgerRequiredCodeRule(message: "seasonal language ledger needs this field"),
            ]
        )
    }
}
