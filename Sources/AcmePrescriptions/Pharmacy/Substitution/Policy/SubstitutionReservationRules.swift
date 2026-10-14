import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution reservation must pass. Check returns its problems, or none.
    protocol SubstitutionReservationRule {
        func check(_ item: SubstitutionReservation) -> [String]
    }

    final class SubstitutionReservationRequiredAllergyRule: SubstitutionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionReservation) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionReservationRequiredTitleRule: SubstitutionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionReservationRetriesRangeRule: SubstitutionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionReservation) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a substitution reservation.
    final class SubstitutionReservationValidator {
        var rules: [any SubstitutionReservationRule]

        init(rules: [any SubstitutionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionReservation]) -> [String: [String]] {
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

    static func defaultSubstitutionReservationValidator() -> SubstitutionReservationValidator {
        return SubstitutionReservationValidator(
            rules: [
                SubstitutionReservationRequiredAllergyRule(message: "substitution reservation needs this field"),
                SubstitutionReservationRequiredTitleRule(message: "substitution reservation needs an entry"),
                SubstitutionReservationRetriesRangeRule(min: 32, max: 64),
            ]
        )
    }
}
