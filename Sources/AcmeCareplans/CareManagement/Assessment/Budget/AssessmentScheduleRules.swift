import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment schedule must pass. Check returns its problems, or none.
    protocol AssessmentScheduleRule {
        func check(_ item: AssessmentSchedule) -> [String]
    }

    final class AssessmentScheduleVisibleGuardRule: AssessmentScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AssessmentSchedule) -> [String] {
            if item.visible && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class AssessmentScheduleTitleLengthRule: AssessmentScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentScheduleRequiredNotesRule: AssessmentScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentSchedule) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentScheduleAcuityRangeRule: AssessmentScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentSchedule) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentScheduleRequiredCodeRule: AssessmentScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment schedule.
    final class AssessmentScheduleValidator {
        var rules: [any AssessmentScheduleRule]

        init(rules: [any AssessmentScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentSchedule) -> [String] {
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

        func requireValid(_ item: AssessmentSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentSchedule]) -> [String: [String]] {
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

    static func defaultAssessmentScheduleValidator() -> AssessmentScheduleValidator {
        return AssessmentScheduleValidator(
            rules: [
                AssessmentScheduleVisibleGuardRule(limit: 32),
                AssessmentScheduleTitleLengthRule(maxLength: 86400),
                AssessmentScheduleRequiredNotesRule(message: "assessment schedule needs a value"),
                AssessmentScheduleAcuityRangeRule(min: 120, max: 86400),
                AssessmentScheduleRequiredCodeRule(message: "assessment schedule needs this field"),
            ]
        )
    }
}
