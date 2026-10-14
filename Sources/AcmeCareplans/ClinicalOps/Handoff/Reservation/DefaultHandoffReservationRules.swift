import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default handoff reservation must pass. Check returns its problems, or none.
    protocol DefaultHandoffReservationRule {
        func check(_ item: DefaultHandoffReservation) -> [String]
    }

    final class DefaultHandoffReservationRequiredEncounterIDRule: DefaultHandoffReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultHandoffReservationBudgetRangeRule: DefaultHandoffReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultHandoffReservationActiveGuardRule: DefaultHandoffReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            if item.active && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DefaultHandoffReservationRequiredCodeRule: DefaultHandoffReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultHandoffReservationCodeLengthRule: DefaultHandoffReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultHandoffReservationDurationMinutesRangeRule: DefaultHandoffReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultHandoffReservation) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default handoff reservation.
    final class DefaultHandoffReservationValidator {
        var rules: [any DefaultHandoffReservationRule]

        init(rules: [any DefaultHandoffReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultHandoffReservation) -> [String] {
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

        func requireValid(_ item: DefaultHandoffReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultHandoffReservation]) -> [String: [String]] {
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

    static func defaultDefaultHandoffReservationValidator() -> DefaultHandoffReservationValidator {
        return DefaultHandoffReservationValidator(
            rules: [
                DefaultHandoffReservationRequiredEncounterIDRule(message: "default handoff reservation needs a value"),
                DefaultHandoffReservationBudgetRangeRule(min: 7.6, max: 4196.2),
                DefaultHandoffReservationActiveGuardRule(limit: 8.5),
                DefaultHandoffReservationRequiredCodeRule(message: "default handoff reservation needs this field"),
                DefaultHandoffReservationCodeLengthRule(maxLength: 80),
                DefaultHandoffReservationDurationMinutesRangeRule(min: 32, max: 120),
            ]
        )
    }
}
