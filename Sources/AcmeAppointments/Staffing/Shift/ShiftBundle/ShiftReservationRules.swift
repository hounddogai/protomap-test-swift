import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift reservation must pass. Check returns its problems, or none.
    protocol ShiftReservationRule {
        func check(_ item: ShiftReservation) -> [String]
    }

    final class ShiftReservationCodePrefixRule: ShiftReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftReservationRequiredDescriptionRule: ShiftReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftReservation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftReservationCapacityRangeRule: ShiftReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftReservation) -> [String] {
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

    /// Runs every rule of a shift reservation.
    final class ShiftReservationValidator {
        var rules: [any ShiftReservationRule]

        init(rules: [any ShiftReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftReservation) -> [String] {
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

        func requireValid(_ item: ShiftReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftReservation]) -> [String: [String]] {
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

    static func defaultShiftReservationValidator() -> ShiftReservationValidator {
        return ShiftReservationValidator(
            rules: [
                ShiftReservationCodePrefixRule(prefix: "X"),
                ShiftReservationRequiredDescriptionRule(message: "shift reservation needs an entry"),
                ShiftReservationCapacityRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
