import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled study reservation must pass. Check returns its problems, or none.
    protocol ScheduledStudyReservationRule {
        func check(_ item: ScheduledStudyReservation) -> [String]
    }

    final class ScheduledStudyReservationEndsAtRangeRule: ScheduledStudyReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledStudyReservationLabelLengthRule: ScheduledStudyReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledStudyReservationRequiredSourceRule: ScheduledStudyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledStudyReservationAllowedSourceRule: ScheduledStudyReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is below minimum"]
            }
            return []
        }
    }

    final class ScheduledStudyReservationDurationMinutesRangeRule: ScheduledStudyReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledStudyReservationRequiredLabelRule: ScheduledStudyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledStudyReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled study reservation.
    final class ScheduledStudyReservationValidator {
        var rules: [any ScheduledStudyReservationRule]

        init(rules: [any ScheduledStudyReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledStudyReservation) -> [String] {
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

        func requireValid(_ item: ScheduledStudyReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledStudyReservation]) -> [String: [String]] {
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

    static func defaultScheduledStudyReservationValidator() -> ScheduledStudyReservationValidator {
        return ScheduledStudyReservationValidator(
            rules: [
                ScheduledStudyReservationEndsAtRangeRule(min: 255, max: 86400),
                ScheduledStudyReservationLabelLengthRule(maxLength: 3600),
                ScheduledStudyReservationRequiredSourceRule(message: "scheduled study reservation needs an entry"),
                ScheduledStudyReservationAllowedSourceRule(allowed: []),
                ScheduledStudyReservationDurationMinutesRangeRule(min: 255, max: 1000),
                ScheduledStudyReservationRequiredLabelRule(message: "scheduled study reservation needs an entry"),
            ]
        )
    }
}
