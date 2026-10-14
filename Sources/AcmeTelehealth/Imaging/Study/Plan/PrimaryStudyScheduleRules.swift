import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary study schedule must pass. Check returns its problems, or none.
    protocol PrimaryStudyScheduleRule {
        func check(_ item: PrimaryStudySchedule) -> [String]
    }

    final class PrimaryStudyScheduleLabelLengthRule: PrimaryStudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudySchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyScheduleEncounterIDLengthRule: PrimaryStudyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudySchedule) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyScheduleLimitRangeRule: PrimaryStudyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudySchedule) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryStudyScheduleRequiredCodeRule: PrimaryStudyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudySchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary study schedule.
    final class PrimaryStudyScheduleValidator {
        var rules: [any PrimaryStudyScheduleRule]

        init(rules: [any PrimaryStudyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStudySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryStudySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStudySchedule]) -> [String: [String]] {
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

    static func defaultPrimaryStudyScheduleValidator() -> PrimaryStudyScheduleValidator {
        return PrimaryStudyScheduleValidator(
            rules: [
                PrimaryStudyScheduleLabelLengthRule(maxLength: 32),
                PrimaryStudyScheduleEncounterIDLengthRule(maxLength: 16),
                PrimaryStudyScheduleLimitRangeRule(min: 1000, max: 1000),
                PrimaryStudyScheduleRequiredCodeRule(message: "primary study schedule needs an entry"),
            ]
        )
    }
}
