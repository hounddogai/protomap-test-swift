import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default specimen reservation must pass. Check returns its problems, or none.
    protocol DefaultSpecimenReservationRule {
        func check(_ item: DefaultSpecimenReservation) -> [String]
    }

    final class DefaultSpecimenReservationRequiredClinicianIDRule: DefaultSpecimenReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenReservation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenReservationRequiredLocaleRule: DefaultSpecimenReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenReservation) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenReservationCodePrefixRule: DefaultSpecimenReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSpecimenReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default specimen reservation.
    final class DefaultSpecimenReservationValidator {
        var rules: [any DefaultSpecimenReservationRule]

        init(rules: [any DefaultSpecimenReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSpecimenReservation) -> [String] {
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

        func requireValid(_ item: DefaultSpecimenReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSpecimenReservation]) -> [String: [String]] {
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

    static func defaultDefaultSpecimenReservationValidator() -> DefaultSpecimenReservationValidator {
        return DefaultSpecimenReservationValidator(
            rules: [
                DefaultSpecimenReservationRequiredClinicianIDRule(
                    message: "default specimen reservation needs a value"
                ),
                DefaultSpecimenReservationRequiredLocaleRule(message: "default specimen reservation needs this field"),
                DefaultSpecimenReservationCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
