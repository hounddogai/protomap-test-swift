import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled shift reservation must pass. Check returns its problems, or none.
    protocol ScheduledShiftReservationRule {
        func check(_ item: ScheduledShiftReservation) -> [String]
    }

    final class ScheduledShiftReservationCodePrefixRule: ScheduledShiftReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledShiftReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledShiftReservationAcuityRangeRule: ScheduledShiftReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledShiftReservation) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledShiftReservationRequiredRegionRule: ScheduledShiftReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledShiftReservation) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledShiftReservationRegionLengthRule: ScheduledShiftReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledShiftReservation) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled shift reservation.
    final class ScheduledShiftReservationValidator {
        var rules: [any ScheduledShiftReservationRule]

        init(rules: [any ScheduledShiftReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledShiftReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledShiftReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledShiftReservation]) -> [String: [String]] {
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

    static func defaultScheduledShiftReservationValidator() -> ScheduledShiftReservationValidator {
        return ScheduledShiftReservationValidator(
            rules: [
                ScheduledShiftReservationCodePrefixRule(prefix: "REF"),
                ScheduledShiftReservationAcuityRangeRule(min: 120, max: 255),
                ScheduledShiftReservationRequiredRegionRule(message: "scheduled shift reservation needs a value"),
                ScheduledShiftReservationRegionLengthRule(maxLength: 86400),
            ]
        )
    }
}
