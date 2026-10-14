import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal follow up reservation must pass. Check returns its problems, or none.
    protocol SeasonalFollowUpReservationRule {
        func check(_ item: SeasonalFollowUpReservation) -> [String]
    }

    final class SeasonalFollowUpReservationRequiredCodeRule: SeasonalFollowUpReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFollowUpReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFollowUpReservationClinicianIDLengthRule: SeasonalFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFollowUpReservation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalFollowUpReservationRequiredPayerRule: SeasonalFollowUpReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFollowUpReservation) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFollowUpReservationRatioRangeRule: SeasonalFollowUpReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFollowUpReservation) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalFollowUpReservationCodeLengthRule: SeasonalFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFollowUpReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal follow up reservation.
    final class SeasonalFollowUpReservationValidator {
        var rules: [any SeasonalFollowUpReservationRule]

        init(rules: [any SeasonalFollowUpReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalFollowUpReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalFollowUpReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalFollowUpReservation]) -> [String: [String]] {
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

    static func defaultSeasonalFollowUpReservationValidator() -> SeasonalFollowUpReservationValidator {
        return SeasonalFollowUpReservationValidator(
            rules: [
                SeasonalFollowUpReservationRequiredCodeRule(
                    message: "seasonal follow up reservation needs this field"
                ),
                SeasonalFollowUpReservationClinicianIDLengthRule(maxLength: 32),
                SeasonalFollowUpReservationRequiredPayerRule(message: "seasonal follow up reservation needs a value"),
                SeasonalFollowUpReservationRatioRangeRule(min: 8.3, max: 3929.8),
                SeasonalFollowUpReservationCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
