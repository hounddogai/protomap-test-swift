import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study reservation must pass. Check returns its problems, or none.
    protocol StudyReservationRule {
        func check(_ item: StudyReservation) -> [String]
    }

    final class StudyReservationAttemptsRangeRule: StudyReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyReservation) -> [String] {
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

    final class StudyReservationPatientRefLengthRule: StudyReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyReservation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyReservationScoreRangeRule: StudyReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyReservation) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyReservationNameLengthRule: StudyReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study reservation.
    final class StudyReservationValidator {
        var rules: [any StudyReservationRule]

        init(rules: [any StudyReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyReservation]) -> [String: [String]] {
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

    static func defaultStudyReservationValidator() -> StudyReservationValidator {
        return StudyReservationValidator(
            rules: [
                StudyReservationAttemptsRangeRule(min: 64, max: 255),
                StudyReservationPatientRefLengthRule(maxLength: 64),
                StudyReservationScoreRangeRule(min: 2.6, max: 3779.0),
                StudyReservationNameLengthRule(maxLength: 120),
            ]
        )
    }
}
