import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen ledger must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenLedgerRule {
        func check(_ item: AdaptiveSpecimenLedger) -> [String]
    }

    final class AdaptiveSpecimenLedgerCountryLengthRule: AdaptiveSpecimenLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenLedger) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenLedgerUpdatedAtRangeRule: AdaptiveSpecimenLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSpecimenLedger) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveSpecimenLedgerRequiredCodeRule: AdaptiveSpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenLedgerAllowedNotesRule: AdaptiveSpecimenLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveSpecimenLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen ledger.
    final class AdaptiveSpecimenLedgerValidator {
        var rules: [any AdaptiveSpecimenLedgerRule]

        init(rules: [any AdaptiveSpecimenLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSpecimenLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenLedger]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenLedgerValidator() -> AdaptiveSpecimenLedgerValidator {
        return AdaptiveSpecimenLedgerValidator(
            rules: [
                AdaptiveSpecimenLedgerCountryLengthRule(maxLength: 64),
                AdaptiveSpecimenLedgerUpdatedAtRangeRule(min: 32, max: 255),
                AdaptiveSpecimenLedgerRequiredCodeRule(message: "adaptive specimen ledger needs this field"),
                AdaptiveSpecimenLedgerAllowedNotesRule(allowed: []),
            ]
        )
    }
}
