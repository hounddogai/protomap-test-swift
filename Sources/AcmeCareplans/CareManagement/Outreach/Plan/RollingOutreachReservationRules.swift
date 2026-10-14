import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling outreach reservation must pass. Check returns its problems, or none.
    protocol RollingOutreachReservationRule {
        func check(_ item: RollingOutreachReservation) -> [String]
    }

    final class RollingOutreachReservationCodeLengthRule: RollingOutreachReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingOutreachReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingOutreachReservationGraceDaysRangeRule: RollingOutreachReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingOutreachReservation) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingOutreachReservationAllowedLabelRule: RollingOutreachReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingOutreachReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class RollingOutreachReservationRequiredCodeRule: RollingOutreachReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOutreachReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling outreach reservation.
    final class RollingOutreachReservationValidator {
        var rules: [any RollingOutreachReservationRule]

        init(rules: [any RollingOutreachReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingOutreachReservation) -> [String] {
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

        func requireValid(_ item: RollingOutreachReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingOutreachReservation]) -> [String: [String]] {
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

    static func defaultRollingOutreachReservationValidator() -> RollingOutreachReservationValidator {
        return RollingOutreachReservationValidator(
            rules: [
                RollingOutreachReservationCodeLengthRule(maxLength: 64),
                RollingOutreachReservationGraceDaysRangeRule(min: 32, max: 255),
                RollingOutreachReservationAllowedLabelRule(allowed: ["global", "weighted"]),
                RollingOutreachReservationRequiredCodeRule(message: "rolling outreach reservation needs a value"),
            ]
        )
    }
}
