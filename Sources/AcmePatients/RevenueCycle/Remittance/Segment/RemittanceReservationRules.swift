import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance reservation must pass. Check returns its problems, or none.
    protocol RemittanceReservationRule {
        func check(_ item: RemittanceReservation) -> [String]
    }

    final class RemittanceReservationRequiredCodeRule: RemittanceReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceReservationClinicianIDLengthRule: RemittanceReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceReservation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceReservationCodePrefixRule: RemittanceReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance reservation.
    final class RemittanceReservationValidator {
        var rules: [any RemittanceReservationRule]

        init(rules: [any RemittanceReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceReservation) -> [String] {
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

        func requireValid(_ item: RemittanceReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceReservation]) -> [String: [String]] {
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

    static func defaultRemittanceReservationValidator() -> RemittanceReservationValidator {
        return RemittanceReservationValidator(
            rules: [
                RemittanceReservationRequiredCodeRule(message: "remittance reservation needs an entry"),
                RemittanceReservationClinicianIDLengthRule(maxLength: 1000),
                RemittanceReservationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
