import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary reservation must pass. Check returns its problems, or none.
    protocol FormularyReservationRule {
        func check(_ item: FormularyReservation) -> [String]
    }

    final class FormularyReservationRequiredUnitRule: FormularyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyReservation) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyReservationCostRangeRule: FormularyReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyReservation) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyReservationUpdatedAtRangeRule: FormularyReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyReservation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyReservationRequiredCodeRule: FormularyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a formulary reservation.
    final class FormularyReservationValidator {
        var rules: [any FormularyReservationRule]

        init(rules: [any FormularyReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyReservation]) -> [String: [String]] {
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

    static func defaultFormularyReservationValidator() -> FormularyReservationValidator {
        return FormularyReservationValidator(
            rules: [
                FormularyReservationRequiredUnitRule(message: "formulary reservation needs an entry"),
                FormularyReservationCostRangeRule(min: 9.3, max: 1480.7),
                FormularyReservationUpdatedAtRangeRule(min: 16, max: 86400),
                FormularyReservationRequiredCodeRule(message: "formulary reservation needs an entry"),
            ]
        )
    }
}
