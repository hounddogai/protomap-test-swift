import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen reservation must pass. Check returns its problems, or none.
    protocol SpecimenReservationRule {
        func check(_ item: SpecimenReservation) -> [String]
    }

    final class SpecimenReservationCapacityRangeRule: SpecimenReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenReservation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenReservationDiagnosisCodeLengthRule: SpecimenReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenReservation) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenReservationStartsAtRangeRule: SpecimenReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenReservation) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenReservationThresholdRangeRule: SpecimenReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenReservation) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenReservationRequiredCodeRule: SpecimenReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenReservationRequiredCurrencyRule: SpecimenReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen reservation.
    final class SpecimenReservationValidator {
        var rules: [any SpecimenReservationRule]

        init(rules: [any SpecimenReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenReservation) -> [String] {
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

        func requireValid(_ item: SpecimenReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenReservation]) -> [String: [String]] {
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

    static func defaultSpecimenReservationValidator() -> SpecimenReservationValidator {
        return SpecimenReservationValidator(
            rules: [
                SpecimenReservationCapacityRangeRule(min: 255, max: 3600),
                SpecimenReservationDiagnosisCodeLengthRule(maxLength: 32),
                SpecimenReservationStartsAtRangeRule(min: 16, max: 86400),
                SpecimenReservationThresholdRangeRule(min: 7.0, max: 2533.4),
                SpecimenReservationRequiredCodeRule(message: "specimen reservation needs this field"),
                SpecimenReservationRequiredCurrencyRule(message: "specimen reservation needs this field"),
            ]
        )
    }
}
