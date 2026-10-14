import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding reservation must pass. Check returns its problems, or none.
    protocol RoundingReservationRule {
        func check(_ item: RoundingReservation) -> [String]
    }

    final class RoundingReservationPatientRefLengthRule: RoundingReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingReservation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingReservationNameLengthRule: RoundingReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingReservationPriorityRangeRule: RoundingReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingReservation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding reservation.
    final class RoundingReservationValidator {
        var rules: [any RoundingReservationRule]

        init(rules: [any RoundingReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingReservation) -> [String] {
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

        func requireValid(_ item: RoundingReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingReservation]) -> [String: [String]] {
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

    static func defaultRoundingReservationValidator() -> RoundingReservationValidator {
        return RoundingReservationValidator(
            rules: [
                RoundingReservationPatientRefLengthRule(maxLength: 255),
                RoundingReservationNameLengthRule(maxLength: 80),
                RoundingReservationPriorityRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
