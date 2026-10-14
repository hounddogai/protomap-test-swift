import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen ledger must pass. Check returns its problems, or none.
    protocol SpecimenLedgerRule {
        func check(_ item: SpecimenLedger) -> [String]
    }

    final class SpecimenLedgerRequiredNameRule: SpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenLedgerRequiredReviewerRule: SpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenLedger) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenLedgerWindowDaysRangeRule: SpecimenLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenLedger) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenLedgerAllowedNameRule: SpecimenLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class SpecimenLedgerRequiredPhoneRule: SpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenLedger) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen ledger.
    final class SpecimenLedgerValidator {
        var rules: [any SpecimenLedgerRule]

        init(rules: [any SpecimenLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenLedger]) -> [String: [String]] {
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

    static func defaultSpecimenLedgerValidator() -> SpecimenLedgerValidator {
        return SpecimenLedgerValidator(
            rules: [
                SpecimenLedgerRequiredNameRule(message: "specimen ledger needs an entry"),
                SpecimenLedgerRequiredReviewerRule(message: "specimen ledger needs this field"),
                SpecimenLedgerWindowDaysRangeRule(min: 80, max: 3600),
                SpecimenLedgerAllowedNameRule(allowed: ["pending"]),
                SpecimenLedgerRequiredPhoneRule(message: "specimen ledger needs an entry"),
            ]
        )
    }
}
