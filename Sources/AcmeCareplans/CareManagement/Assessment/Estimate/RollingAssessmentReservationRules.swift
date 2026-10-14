import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling assessment reservation must pass. Check returns its problems, or none.
    protocol RollingAssessmentReservationRule {
        func check(_ item: RollingAssessmentReservation) -> [String]
    }

    final class RollingAssessmentReservationNameLengthRule: RollingAssessmentReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAssessmentReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAssessmentReservationQuantityRangeRule: RollingAssessmentReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAssessmentReservation) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingAssessmentReservationAmountRangeRule: RollingAssessmentReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAssessmentReservation) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling assessment reservation.
    final class RollingAssessmentReservationValidator {
        var rules: [any RollingAssessmentReservationRule]

        init(rules: [any RollingAssessmentReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAssessmentReservation) -> [String] {
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

        func requireValid(_ item: RollingAssessmentReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAssessmentReservation]) -> [String: [String]] {
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

    static func defaultRollingAssessmentReservationValidator() -> RollingAssessmentReservationValidator {
        return RollingAssessmentReservationValidator(
            rules: [
                RollingAssessmentReservationNameLengthRule(maxLength: 255),
                RollingAssessmentReservationQuantityRangeRule(min: 80, max: 1000),
                RollingAssessmentReservationAmountRangeRule(min: 2.1, max: 4110.6),
            ]
        )
    }
}
