import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime reservation must pass. Check returns its problems, or none.
    protocol OvertimeReservationRule {
        func check(_ item: OvertimeReservation) -> [String]
    }

    final class OvertimeReservationRequiredClinicianIDRule: OvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeReservation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeReservationClinicianIDLengthRule: OvertimeReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeReservation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeReservationDosageMgRangeRule: OvertimeReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeReservation) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeReservationRequiredCodeRule: OvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeReservationRequiredSourceRule: OvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeReservation) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeReservationAllowedClinicianIDRule: OvertimeReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime reservation.
    final class OvertimeReservationValidator {
        var rules: [any OvertimeReservationRule]

        init(rules: [any OvertimeReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeReservation) -> [String] {
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

        func requireValid(_ item: OvertimeReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeReservation]) -> [String: [String]] {
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

    static func defaultOvertimeReservationValidator() -> OvertimeReservationValidator {
        return OvertimeReservationValidator(
            rules: [
                OvertimeReservationRequiredClinicianIDRule(message: "overtime reservation needs a value"),
                OvertimeReservationClinicianIDLengthRule(maxLength: 1000),
                OvertimeReservationDosageMgRangeRule(min: 1.8, max: 2276.8),
                OvertimeReservationRequiredCodeRule(message: "overtime reservation needs this field"),
                OvertimeReservationRequiredSourceRule(message: "overtime reservation needs an entry"),
                OvertimeReservationAllowedClinicianIDRule(allowed: []),
            ]
        )
    }
}
