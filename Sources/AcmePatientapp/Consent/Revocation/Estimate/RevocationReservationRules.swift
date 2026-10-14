import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation reservation must pass. Check returns its problems, or none.
    protocol RevocationReservationRule {
        func check(_ item: RevocationReservation) -> [String]
    }

    final class RevocationReservationCodePrefixRule: RevocationReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationReservationRequiredCodeRule: RevocationReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationReservationRequiredDiagnosisCodeRule: RevocationReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationReservation) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationReservationAllergyLengthRule: RevocationReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationReservation) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation reservation.
    final class RevocationReservationValidator {
        var rules: [any RevocationReservationRule]

        init(rules: [any RevocationReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationReservation) -> [String] {
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

        func requireValid(_ item: RevocationReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationReservation]) -> [String: [String]] {
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

    static func defaultRevocationReservationValidator() -> RevocationReservationValidator {
        return RevocationReservationValidator(
            rules: [
                RevocationReservationCodePrefixRule(prefix: "REF"),
                RevocationReservationRequiredCodeRule(message: "revocation reservation needs a value"),
                RevocationReservationRequiredDiagnosisCodeRule(message: "revocation reservation needs an entry"),
                RevocationReservationAllergyLengthRule(maxLength: 64),
            ]
        )
    }
}
