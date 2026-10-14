import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient result schedule must pass. Check returns its problems, or none.
    protocol LenientResultScheduleRule {
        func check(_ item: LenientResultSchedule) -> [String]
    }

    final class LenientResultScheduleRequiredLabelRule: LenientResultScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientResultSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientResultSchedulePriorityRangeRule: LenientResultScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientResultSchedule) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientResultScheduleCodeLengthRule: LenientResultScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientResultSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientResultScheduleLimitRangeRule: LenientResultScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientResultSchedule) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient result schedule.
    final class LenientResultScheduleValidator {
        var rules: [any LenientResultScheduleRule]

        init(rules: [any LenientResultScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientResultSchedule) -> [String] {
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

        func requireValid(_ item: LenientResultSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientResultSchedule]) -> [String: [String]] {
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

    static func defaultLenientResultScheduleValidator() -> LenientResultScheduleValidator {
        return LenientResultScheduleValidator(
            rules: [
                LenientResultScheduleRequiredLabelRule(message: "lenient result schedule needs this field"),
                LenientResultSchedulePriorityRangeRule(min: 255, max: 86400),
                LenientResultScheduleCodeLengthRule(maxLength: 86400),
                LenientResultScheduleLimitRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
