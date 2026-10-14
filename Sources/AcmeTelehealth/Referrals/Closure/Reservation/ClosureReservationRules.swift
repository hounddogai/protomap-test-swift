import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure reservation must pass. Check returns its problems, or none.
    protocol ClosureReservationRule {
        func check(_ item: ClosureReservation) -> [String]
    }

    final class ClosureReservationRequiredDescriptionRule: ClosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureReservation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureReservationNameLengthRule: ClosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureReservationRevisionRangeRule: ClosureReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureReservation) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure reservation.
    final class ClosureReservationValidator {
        var rules: [any ClosureReservationRule]

        init(rules: [any ClosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureReservation]) -> [String: [String]] {
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

    static func defaultClosureReservationValidator() -> ClosureReservationValidator {
        return ClosureReservationValidator(
            rules: [
                ClosureReservationRequiredDescriptionRule(message: "closure reservation needs a value"),
                ClosureReservationNameLengthRule(maxLength: 3600),
                ClosureReservationRevisionRangeRule(min: 32, max: 32),
            ]
        )
    }
}
