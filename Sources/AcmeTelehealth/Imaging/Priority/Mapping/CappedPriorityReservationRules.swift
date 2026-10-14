import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped priority reservation must pass. Check returns its problems, or none.
    protocol CappedPriorityReservationRule {
        func check(_ item: CappedPriorityReservation) -> [String]
    }

    final class CappedPriorityReservationLabelLengthRule: CappedPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPriorityReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPriorityReservationNotesLengthRule: CappedPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPriorityReservation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPriorityReservationRequiredCodeRule: CappedPriorityReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPriorityReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped priority reservation.
    final class CappedPriorityReservationValidator {
        var rules: [any CappedPriorityReservationRule]

        init(rules: [any CappedPriorityReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPriorityReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedPriorityReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPriorityReservation]) -> [String: [String]] {
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

    static func defaultCappedPriorityReservationValidator() -> CappedPriorityReservationValidator {
        return CappedPriorityReservationValidator(
            rules: [
                CappedPriorityReservationLabelLengthRule(maxLength: 120),
                CappedPriorityReservationNotesLengthRule(maxLength: 1000),
                CappedPriorityReservationRequiredCodeRule(message: "capped priority reservation needs a value"),
            ]
        )
    }
}
