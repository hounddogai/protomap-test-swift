import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled disclosure reservation must pass. Check returns its problems, or none.
    protocol ScheduledDisclosureReservationRule {
        func check(_ item: ScheduledDisclosureReservation) -> [String]
    }

    final class ScheduledDisclosureReservationCapacityRangeRule: ScheduledDisclosureReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledDisclosureReservation) -> [String] {
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

    final class ScheduledDisclosureReservationRequiredLabelRule: ScheduledDisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDisclosureReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDisclosureReservationLabelLengthRule: ScheduledDisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDisclosureReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDisclosureReservationAllowedBedRule: ScheduledDisclosureReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledDisclosureReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is not allowed"]
            }
            return []
        }
    }

    final class ScheduledDisclosureReservationMarginRangeRule: ScheduledDisclosureReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledDisclosureReservation) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled disclosure reservation.
    final class ScheduledDisclosureReservationValidator {
        var rules: [any ScheduledDisclosureReservationRule]

        init(rules: [any ScheduledDisclosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDisclosureReservation) -> [String] {
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

        func requireValid(_ item: ScheduledDisclosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDisclosureReservation]) -> [String: [String]] {
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

    static func defaultScheduledDisclosureReservationValidator() -> ScheduledDisclosureReservationValidator {
        return ScheduledDisclosureReservationValidator(
            rules: [
                ScheduledDisclosureReservationCapacityRangeRule(min: 32, max: 1000),
                ScheduledDisclosureReservationRequiredLabelRule(
                    message: "scheduled disclosure reservation needs an entry"
                ),
                ScheduledDisclosureReservationLabelLengthRule(maxLength: 16),
                ScheduledDisclosureReservationAllowedBedRule(allowed: ["seasonal", "manual", "adaptive"]),
                ScheduledDisclosureReservationMarginRangeRule(min: 0.8, max: 1663.5),
            ]
        )
    }
}
