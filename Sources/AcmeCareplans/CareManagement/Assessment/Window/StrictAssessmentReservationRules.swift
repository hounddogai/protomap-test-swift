import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict assessment reservation must pass. Check returns its problems, or none.
    protocol StrictAssessmentReservationRule {
        func check(_ item: StrictAssessmentReservation) -> [String]
    }

    final class StrictAssessmentReservationCountryLengthRule: StrictAssessmentReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAssessmentReservation) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAssessmentReservationCodePrefixRule: StrictAssessmentReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictAssessmentReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictAssessmentReservationCostRangeRule: StrictAssessmentReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAssessmentReservation) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictAssessmentReservationLabelLengthRule: StrictAssessmentReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictAssessmentReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictAssessmentReservationCapacityRangeRule: StrictAssessmentReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAssessmentReservation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict assessment reservation.
    final class StrictAssessmentReservationValidator {
        var rules: [any StrictAssessmentReservationRule]

        init(rules: [any StrictAssessmentReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAssessmentReservation) -> [String] {
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

        func requireValid(_ item: StrictAssessmentReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAssessmentReservation]) -> [String: [String]] {
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

    static func defaultStrictAssessmentReservationValidator() -> StrictAssessmentReservationValidator {
        return StrictAssessmentReservationValidator(
            rules: [
                StrictAssessmentReservationCountryLengthRule(maxLength: 120),
                StrictAssessmentReservationCodePrefixRule(prefix: "X"),
                StrictAssessmentReservationCostRangeRule(min: 0.4, max: 4060.2),
                StrictAssessmentReservationLabelLengthRule(maxLength: 1000),
                StrictAssessmentReservationCapacityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
