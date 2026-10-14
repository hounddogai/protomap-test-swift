import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance reservation must pass. Check returns its problems, or none.
    protocol DefaultRemittanceReservationRule {
        func check(_ item: DefaultRemittanceReservation) -> [String]
    }

    final class DefaultRemittanceReservationRequiredClinicianIDRule: DefaultRemittanceReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceReservationDiagnosisCodeLengthRule: DefaultRemittanceReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceReservationPinnedGuardRule: DefaultRemittanceReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DefaultRemittanceReservationTitleLengthRule: DefaultRemittanceReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceReservationAllowedDiagnosisCodeRule: DefaultRemittanceReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is not allowed"]
            }
            return []
        }
    }

    final class DefaultRemittanceReservationCodePrefixRule: DefaultRemittanceReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRemittanceReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance reservation.
    final class DefaultRemittanceReservationValidator {
        var rules: [any DefaultRemittanceReservationRule]

        init(rules: [any DefaultRemittanceReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRemittanceReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceReservation]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceReservationValidator() -> DefaultRemittanceReservationValidator {
        return DefaultRemittanceReservationValidator(
            rules: [
                DefaultRemittanceReservationRequiredClinicianIDRule(
                    message: "default remittance reservation needs an entry"
                ),
                DefaultRemittanceReservationDiagnosisCodeLengthRule(maxLength: 255),
                DefaultRemittanceReservationPinnedGuardRule(limit: 7.2),
                DefaultRemittanceReservationTitleLengthRule(maxLength: 80),
                DefaultRemittanceReservationAllowedDiagnosisCodeRule(allowed: []),
                DefaultRemittanceReservationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
