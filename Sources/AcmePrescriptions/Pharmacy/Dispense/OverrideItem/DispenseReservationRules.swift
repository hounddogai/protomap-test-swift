import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense reservation must pass. Check returns its problems, or none.
    protocol DispenseReservationRule {
        func check(_ item: DispenseReservation) -> [String]
    }

    final class DispenseReservationRequiredCodeRule: DispenseReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseReservationPriorityRangeRule: DispenseReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseReservation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseReservationRequiredPatientRefRule: DispenseReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseReservation) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseReservationPatientRefLengthRule: DispenseReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseReservation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseReservationRequiredLabelRule: DispenseReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense reservation.
    final class DispenseReservationValidator {
        var rules: [any DispenseReservationRule]

        init(rules: [any DispenseReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseReservation]) -> [String: [String]] {
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

    static func defaultDispenseReservationValidator() -> DispenseReservationValidator {
        return DispenseReservationValidator(
            rules: [
                DispenseReservationRequiredCodeRule(message: "dispense reservation needs this field"),
                DispenseReservationPriorityRangeRule(min: 32, max: 1000),
                DispenseReservationRequiredPatientRefRule(message: "dispense reservation needs an entry"),
                DispenseReservationPatientRefLengthRule(maxLength: 120),
                DispenseReservationRequiredLabelRule(message: "dispense reservation needs this field"),
            ]
        )
    }
}
