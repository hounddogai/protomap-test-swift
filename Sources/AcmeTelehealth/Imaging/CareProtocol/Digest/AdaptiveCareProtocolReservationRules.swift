import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive care protocol reservation must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolReservationRule {
        func check(_ item: AdaptiveCareProtocolReservation) -> [String]
    }

    final class AdaptiveCareProtocolReservationAllowedClinicianIDRule: AdaptiveCareProtocolReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCareProtocolReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolReservationArchivedGuardRule: AdaptiveCareProtocolReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveCareProtocolReservation) -> [String] {
            if item.archived && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolReservationNameLengthRule: AdaptiveCareProtocolReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolReservationRequiredCodeRule: AdaptiveCareProtocolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareProtocolReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care protocol reservation.
    final class AdaptiveCareProtocolReservationValidator {
        var rules: [any AdaptiveCareProtocolReservationRule]

        init(rules: [any AdaptiveCareProtocolReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolReservation) -> [String] {
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

        func requireValid(_ item: AdaptiveCareProtocolReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolReservation]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolReservationValidator() -> AdaptiveCareProtocolReservationValidator {
        return AdaptiveCareProtocolReservationValidator(
            rules: [
                AdaptiveCareProtocolReservationAllowedClinicianIDRule(allowed: ["strict", "tiered"]),
                AdaptiveCareProtocolReservationArchivedGuardRule(limit: 120),
                AdaptiveCareProtocolReservationNameLengthRule(maxLength: 86400),
                AdaptiveCareProtocolReservationRequiredCodeRule(
                    message: "adaptive care protocol reservation needs a value"
                ),
            ]
        )
    }
}
