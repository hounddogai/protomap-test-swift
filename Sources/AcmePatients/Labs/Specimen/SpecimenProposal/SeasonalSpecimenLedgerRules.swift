import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal specimen ledger must pass. Check returns its problems, or none.
    protocol SeasonalSpecimenLedgerRule {
        func check(_ item: SeasonalSpecimenLedger) -> [String]
    }

    final class SeasonalSpecimenLedgerCreatedAtRangeRule: SeasonalSpecimenLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSpecimenLedger) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSpecimenLedgerRequiredLabelRule: SeasonalSpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSpecimenLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSpecimenLedgerAllergyLengthRule: SeasonalSpecimenLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSpecimenLedger) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenLedgerAllowedChecksumRule: SeasonalSpecimenLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSpecimenLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is unknown"]
            }
            return []
        }
    }

    final class SeasonalSpecimenLedgerRequiredAllergyRule: SeasonalSpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSpecimenLedger) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal specimen ledger.
    final class SeasonalSpecimenLedgerValidator {
        var rules: [any SeasonalSpecimenLedgerRule]

        init(rules: [any SeasonalSpecimenLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSpecimenLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSpecimenLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSpecimenLedger]) -> [String: [String]] {
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

    static func defaultSeasonalSpecimenLedgerValidator() -> SeasonalSpecimenLedgerValidator {
        return SeasonalSpecimenLedgerValidator(
            rules: [
                SeasonalSpecimenLedgerCreatedAtRangeRule(min: 1000, max: 1000),
                SeasonalSpecimenLedgerRequiredLabelRule(message: "seasonal specimen ledger needs this field"),
                SeasonalSpecimenLedgerAllergyLengthRule(maxLength: 1000),
                SeasonalSpecimenLedgerAllowedChecksumRule(allowed: ["default", "capped"]),
                SeasonalSpecimenLedgerRequiredAllergyRule(message: "seasonal specimen ledger needs an entry"),
            ]
        )
    }
}
