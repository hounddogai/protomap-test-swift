import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form reservation must pass. Check returns its problems, or none.
    protocol ConsentFormReservationRule {
        func check(_ item: ConsentFormReservation) -> [String]
    }

    final class ConsentFormReservationCodeLengthRule: ConsentFormReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormReservationUpdatedAtRangeRule: ConsentFormReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormReservation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormReservationRequiredCodeRule: ConsentFormReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form reservation.
    final class ConsentFormReservationValidator {
        var rules: [any ConsentFormReservationRule]

        init(rules: [any ConsentFormReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormReservation]) -> [String: [String]] {
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

    static func defaultConsentFormReservationValidator() -> ConsentFormReservationValidator {
        return ConsentFormReservationValidator(
            rules: [
                ConsentFormReservationCodeLengthRule(maxLength: 32),
                ConsentFormReservationUpdatedAtRangeRule(min: 120, max: 120),
                ConsentFormReservationRequiredCodeRule(message: "consent form reservation needs a value"),
            ]
        )
    }
}
