import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession reservation must pass. Check returns its problems, or none.
    protocol AccessionReservationRule {
        func check(_ item: AccessionReservation) -> [String]
    }

    final class AccessionReservationRequiredCodeRule: AccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionReservationLabelLengthRule: AccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionReservationAttemptsRangeRule: AccessionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionReservation) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionReservationCodePrefixRule: AccessionReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionReservationCodeLengthRule: AccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionReservationExpiresAtRangeRule: AccessionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionReservation) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession reservation.
    final class AccessionReservationValidator {
        var rules: [any AccessionReservationRule]

        init(rules: [any AccessionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionReservation]) -> [String: [String]] {
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

    static func defaultAccessionReservationValidator() -> AccessionReservationValidator {
        return AccessionReservationValidator(
            rules: [
                AccessionReservationRequiredCodeRule(message: "accession reservation needs an entry"),
                AccessionReservationLabelLengthRule(maxLength: 80),
                AccessionReservationAttemptsRangeRule(min: 16, max: 80),
                AccessionReservationCodePrefixRule(prefix: "REF"),
                AccessionReservationCodeLengthRule(maxLength: 255),
                AccessionReservationExpiresAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
