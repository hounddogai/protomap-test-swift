import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling disclosure reservation must pass. Check returns its problems, or none.
    protocol RollingDisclosureReservationRule {
        func check(_ item: RollingDisclosureReservation) -> [String]
    }

    final class RollingDisclosureReservationPhoneLengthRule: RollingDisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDisclosureReservationRequiredBedRule: RollingDisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDisclosureReservationCodeLengthRule: RollingDisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDisclosureReservationRequiredPhoneRule: RollingDisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDisclosureReservationRequiredNameRule: RollingDisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDisclosureReservationBudgetRangeRule: RollingDisclosureReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDisclosureReservation) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling disclosure reservation.
    final class RollingDisclosureReservationValidator {
        var rules: [any RollingDisclosureReservationRule]

        init(rules: [any RollingDisclosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDisclosureReservation) -> [String] {
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

        func requireValid(_ item: RollingDisclosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDisclosureReservation]) -> [String: [String]] {
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

    static func defaultRollingDisclosureReservationValidator() -> RollingDisclosureReservationValidator {
        return RollingDisclosureReservationValidator(
            rules: [
                RollingDisclosureReservationPhoneLengthRule(maxLength: 32),
                RollingDisclosureReservationRequiredBedRule(message: "rolling disclosure reservation needs an entry"),
                RollingDisclosureReservationCodeLengthRule(maxLength: 16),
                RollingDisclosureReservationRequiredPhoneRule(
                    message: "rolling disclosure reservation needs an entry"
                ),
                RollingDisclosureReservationRequiredNameRule(
                    message: "rolling disclosure reservation needs this field"
                ),
                RollingDisclosureReservationBudgetRangeRule(min: 9.4, max: 1046.3),
            ]
        )
    }
}
