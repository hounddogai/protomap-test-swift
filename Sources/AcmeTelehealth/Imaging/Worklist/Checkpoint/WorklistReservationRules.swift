import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist reservation must pass. Check returns its problems, or none.
    protocol WorklistReservationRule {
        func check(_ item: WorklistReservation) -> [String]
    }

    final class WorklistReservationVisitMinutesRangeRule: WorklistReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistReservation) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistReservationRequiredTitleRule: WorklistReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistReservationSpecialtyLengthRule: WorklistReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistReservation) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistReservationRetriesRangeRule: WorklistReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistReservation) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist reservation.
    final class WorklistReservationValidator {
        var rules: [any WorklistReservationRule]

        init(rules: [any WorklistReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistReservation]) -> [String: [String]] {
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

    static func defaultWorklistReservationValidator() -> WorklistReservationValidator {
        return WorklistReservationValidator(
            rules: [
                WorklistReservationVisitMinutesRangeRule(min: 255, max: 1000),
                WorklistReservationRequiredTitleRule(message: "worklist reservation needs an entry"),
                WorklistReservationSpecialtyLengthRule(maxLength: 120),
                WorklistReservationRetriesRangeRule(min: 120, max: 255),
            ]
        )
    }
}
