import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending bed board schedule must pass. Check returns its problems, or none.
    protocol PendingBedBoardScheduleRule {
        func check(_ item: PendingBedBoardSchedule) -> [String]
    }

    final class PendingBedBoardScheduleRequiredCountryRule: PendingBedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingBedBoardSchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingBedBoardScheduleApprovedGuardRule: PendingBedBoardScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingBedBoardSchedule) -> [String] {
            if item.approved && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PendingBedBoardScheduleDurationMinutesRangeRule: PendingBedBoardScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingBedBoardSchedule) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingBedBoardScheduleNotesLengthRule: PendingBedBoardScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingBedBoardSchedule) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending bed board schedule.
    final class PendingBedBoardScheduleValidator {
        var rules: [any PendingBedBoardScheduleRule]

        init(rules: [any PendingBedBoardScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingBedBoardSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingBedBoardSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingBedBoardSchedule]) -> [String: [String]] {
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

    static func defaultPendingBedBoardScheduleValidator() -> PendingBedBoardScheduleValidator {
        return PendingBedBoardScheduleValidator(
            rules: [
                PendingBedBoardScheduleRequiredCountryRule(message: "pending bed board schedule needs a value"),
                PendingBedBoardScheduleApprovedGuardRule(limit: 64),
                PendingBedBoardScheduleDurationMinutesRangeRule(min: 64, max: 1000),
                PendingBedBoardScheduleNotesLengthRule(maxLength: 64),
            ]
        )
    }
}
