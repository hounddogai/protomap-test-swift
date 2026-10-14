import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending shift reservation must pass. Check returns its problems, or none.
    protocol PendingShiftReservationRule {
        func check(_ item: PendingShiftReservation) -> [String]
    }

    final class PendingShiftReservationAllowedNotesRule: PendingShiftReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingShiftReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is missing"]
            }
            return []
        }
    }

    final class PendingShiftReservationRequiredCodeRule: PendingShiftReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingShiftReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingShiftReservationVisibleGuardRule: PendingShiftReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingShiftReservation) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a pending shift reservation.
    final class PendingShiftReservationValidator {
        var rules: [any PendingShiftReservationRule]

        init(rules: [any PendingShiftReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingShiftReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingShiftReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingShiftReservation]) -> [String: [String]] {
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

    static func defaultPendingShiftReservationValidator() -> PendingShiftReservationValidator {
        return PendingShiftReservationValidator(
            rules: [
                PendingShiftReservationAllowedNotesRule(allowed: ["batched"]),
                PendingShiftReservationRequiredCodeRule(message: "pending shift reservation needs an entry"),
                PendingShiftReservationVisibleGuardRule(limit: 7.3),
            ]
        )
    }
}
