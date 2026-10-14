import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study schedule must pass. Check returns its problems, or none.
    protocol StudyScheduleRule {
        func check(_ item: StudySchedule) -> [String]
    }

    final class StudyScheduleCapacityRangeRule: StudyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudySchedule) -> [String] {
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

    final class StudyScheduleReviewerLengthRule: StudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySchedule) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyScheduleCodeLengthRule: StudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyScheduleNameLengthRule: StudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyScheduleRequiredCodeRule: StudyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudySchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study schedule.
    final class StudyScheduleValidator {
        var rules: [any StudyScheduleRule]

        init(rules: [any StudyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: StudySchedule) -> [String] {
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

        func requireValid(_ item: StudySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudySchedule]) -> [String: [String]] {
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

    static func defaultStudyScheduleValidator() -> StudyScheduleValidator {
        return StudyScheduleValidator(
            rules: [
                StudyScheduleCapacityRangeRule(min: 120, max: 3600),
                StudyScheduleReviewerLengthRule(maxLength: 120),
                StudyScheduleCodeLengthRule(maxLength: 64),
                StudyScheduleNameLengthRule(maxLength: 86400),
                StudyScheduleRequiredCodeRule(message: "study schedule needs an entry"),
            ]
        )
    }
}
