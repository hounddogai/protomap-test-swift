import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift reservation must pass. Check returns its problems, or none.
    protocol DefaultShiftReservationRule {
        func check(_ item: DefaultShiftReservation) -> [String]
    }

    final class DefaultShiftReservationAllowedEncounterIDRule: DefaultShiftReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultShiftReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is stale"]
            }
            return []
        }
    }

    final class DefaultShiftReservationCapacityRangeRule: DefaultShiftReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftReservation) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultShiftReservationDurationMinutesRangeRule: DefaultShiftReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftReservation) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultShiftReservationNameLengthRule: DefaultShiftReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default shift reservation.
    final class DefaultShiftReservationValidator {
        var rules: [any DefaultShiftReservationRule]

        init(rules: [any DefaultShiftReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultShiftReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftReservation]) -> [String: [String]] {
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

    static func defaultDefaultShiftReservationValidator() -> DefaultShiftReservationValidator {
        return DefaultShiftReservationValidator(
            rules: [
                DefaultShiftReservationAllowedEncounterIDRule(allowed: []),
                DefaultShiftReservationCapacityRangeRule(min: 32, max: 1000),
                DefaultShiftReservationDurationMinutesRangeRule(min: 80, max: 1000),
                DefaultShiftReservationNameLengthRule(maxLength: 80),
            ]
        )
    }
}
