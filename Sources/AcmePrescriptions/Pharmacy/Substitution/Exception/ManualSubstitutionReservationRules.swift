import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual substitution reservation must pass. Check returns its problems, or none.
    protocol ManualSubstitutionReservationRule {
        func check(_ item: ManualSubstitutionReservation) -> [String]
    }

    final class ManualSubstitutionReservationNotesLengthRule: ManualSubstitutionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSubstitutionReservation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSubstitutionReservationAllowedLabelRule: ManualSubstitutionReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualSubstitutionReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class ManualSubstitutionReservationRequiredCodeRule: ManualSubstitutionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSubstitutionReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSubstitutionReservationAcuityRangeRule: ManualSubstitutionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSubstitutionReservation) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualSubstitutionReservationStartsAtRangeRule: ManualSubstitutionReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSubstitutionReservation) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual substitution reservation.
    final class ManualSubstitutionReservationValidator {
        var rules: [any ManualSubstitutionReservationRule]

        init(rules: [any ManualSubstitutionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSubstitutionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSubstitutionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSubstitutionReservation]) -> [String: [String]] {
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

    static func defaultManualSubstitutionReservationValidator() -> ManualSubstitutionReservationValidator {
        return ManualSubstitutionReservationValidator(
            rules: [
                ManualSubstitutionReservationNotesLengthRule(maxLength: 86400),
                ManualSubstitutionReservationAllowedLabelRule(allowed: ["global", "adaptive"]),
                ManualSubstitutionReservationRequiredCodeRule(
                    message: "manual substitution reservation needs an entry"
                ),
                ManualSubstitutionReservationAcuityRangeRule(min: 1000, max: 3600),
                ManualSubstitutionReservationStartsAtRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
