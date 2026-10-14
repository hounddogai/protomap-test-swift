import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict closure reservation must pass. Check returns its problems, or none.
    protocol StrictClosureReservationRule {
        func check(_ item: StrictClosureReservation) -> [String]
    }

    final class StrictClosureReservationRequiredTimezoneRule: StrictClosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClosureReservation) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClosureReservationLabelLengthRule: StrictClosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClosureReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictClosureReservationCodeLengthRule: StrictClosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClosureReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict closure reservation.
    final class StrictClosureReservationValidator {
        var rules: [any StrictClosureReservationRule]

        init(rules: [any StrictClosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClosureReservation) -> [String] {
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

        func requireValid(_ item: StrictClosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClosureReservation]) -> [String: [String]] {
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

    static func defaultStrictClosureReservationValidator() -> StrictClosureReservationValidator {
        return StrictClosureReservationValidator(
            rules: [
                StrictClosureReservationRequiredTimezoneRule(message: "strict closure reservation needs this field"),
                StrictClosureReservationLabelLengthRule(maxLength: 86400),
                StrictClosureReservationCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
