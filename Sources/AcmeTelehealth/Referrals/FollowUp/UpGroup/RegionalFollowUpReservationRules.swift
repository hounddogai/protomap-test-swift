import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional follow up reservation must pass. Check returns its problems, or none.
    protocol RegionalFollowUpReservationRule {
        func check(_ item: RegionalFollowUpReservation) -> [String]
    }

    final class RegionalFollowUpReservationFacilityLengthRule: RegionalFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFollowUpReservation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFollowUpReservationCodeLengthRule: RegionalFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFollowUpReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFollowUpReservationRequiredCodeRule: RegionalFollowUpReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFollowUpReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional follow up reservation.
    final class RegionalFollowUpReservationValidator {
        var rules: [any RegionalFollowUpReservationRule]

        init(rules: [any RegionalFollowUpReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFollowUpReservation) -> [String] {
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

        func requireValid(_ item: RegionalFollowUpReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFollowUpReservation]) -> [String: [String]] {
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

    static func defaultRegionalFollowUpReservationValidator() -> RegionalFollowUpReservationValidator {
        return RegionalFollowUpReservationValidator(
            rules: [
                RegionalFollowUpReservationFacilityLengthRule(maxLength: 80),
                RegionalFollowUpReservationCodeLengthRule(maxLength: 1000),
                RegionalFollowUpReservationRequiredCodeRule(message: "regional follow up reservation needs a value"),
            ]
        )
    }
}
