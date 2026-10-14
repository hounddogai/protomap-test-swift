import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional accession reservation must pass. Check returns its problems, or none.
    protocol RegionalAccessionReservationRule {
        func check(_ item: RegionalAccessionReservation) -> [String]
    }

    final class RegionalAccessionReservationAttemptsRangeRule: RegionalAccessionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAccessionReservation) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAccessionReservationPriorityRangeRule: RegionalAccessionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAccessionReservation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAccessionReservationRequiredLabelRule: RegionalAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAccessionReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAccessionReservationCodeLengthRule: RegionalAccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAccessionReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional accession reservation.
    final class RegionalAccessionReservationValidator {
        var rules: [any RegionalAccessionReservationRule]

        init(rules: [any RegionalAccessionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAccessionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAccessionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAccessionReservation]) -> [String: [String]] {
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

    static func defaultRegionalAccessionReservationValidator() -> RegionalAccessionReservationValidator {
        return RegionalAccessionReservationValidator(
            rules: [
                RegionalAccessionReservationAttemptsRangeRule(min: 120, max: 255),
                RegionalAccessionReservationPriorityRangeRule(min: 64, max: 255),
                RegionalAccessionReservationRequiredLabelRule(
                    message: "regional accession reservation needs this field"
                ),
                RegionalAccessionReservationCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
