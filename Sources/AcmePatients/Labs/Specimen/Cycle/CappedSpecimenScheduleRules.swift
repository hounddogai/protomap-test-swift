import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped specimen schedule must pass. Check returns its problems, or none.
    protocol CappedSpecimenScheduleRule {
        func check(_ item: CappedSpecimenSchedule) -> [String]
    }

    final class CappedSpecimenScheduleCodeLengthRule: CappedSpecimenScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSpecimenScheduleRequiredFacilityRule: CappedSpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSpecimenSchedule) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSpecimenScheduleVisitMinutesRangeRule: CappedSpecimenScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSpecimenSchedule) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedSpecimenScheduleRequiredNameRule: CappedSpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSpecimenSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedSpecimenScheduleFacilityLengthRule: CappedSpecimenScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSpecimenSchedule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped specimen schedule.
    final class CappedSpecimenScheduleValidator {
        var rules: [any CappedSpecimenScheduleRule]

        init(rules: [any CappedSpecimenScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSpecimenSchedule) -> [String] {
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

        func requireValid(_ item: CappedSpecimenSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSpecimenSchedule]) -> [String: [String]] {
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

    static func defaultCappedSpecimenScheduleValidator() -> CappedSpecimenScheduleValidator {
        return CappedSpecimenScheduleValidator(
            rules: [
                CappedSpecimenScheduleCodeLengthRule(maxLength: 120),
                CappedSpecimenScheduleRequiredFacilityRule(message: "capped specimen schedule needs a value"),
                CappedSpecimenScheduleVisitMinutesRangeRule(min: 16, max: 86400),
                CappedSpecimenScheduleRequiredNameRule(message: "capped specimen schedule needs this field"),
                CappedSpecimenScheduleFacilityLengthRule(maxLength: 80),
            ]
        )
    }
}
