import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority schedule must pass. Check returns its problems, or none.
    protocol PriorityScheduleRule {
        func check(_ item: PrioritySchedule) -> [String]
    }

    final class PriorityScheduleSequenceRangeRule: PriorityScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySchedule) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityScheduleLabelLengthRule: PriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityScheduleGraceDaysRangeRule: PriorityScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrioritySchedule) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityScheduleCodeLengthRule: PriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority schedule.
    final class PriorityScheduleValidator {
        var rules: [any PriorityScheduleRule]

        init(rules: [any PriorityScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrioritySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrioritySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrioritySchedule]) -> [String: [String]] {
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

    static func defaultPriorityScheduleValidator() -> PriorityScheduleValidator {
        return PriorityScheduleValidator(
            rules: [
                PriorityScheduleSequenceRangeRule(min: 32, max: 1000),
                PriorityScheduleLabelLengthRule(maxLength: 64),
                PriorityScheduleGraceDaysRangeRule(min: 255, max: 3600),
                PriorityScheduleCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
