import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift schedule must pass. Check returns its problems, or none.
    protocol ShiftScheduleRule {
        func check(_ item: ShiftSchedule) -> [String]
    }

    final class ShiftScheduleThresholdRangeRule: ShiftScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftSchedule) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftScheduleRequiredReviewerRule: ShiftScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftSchedule) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftScheduleCodePrefixRule: ShiftScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftScheduleRefillsRangeRule: ShiftScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftSchedule) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftScheduleLabelLengthRule: ShiftScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift schedule.
    final class ShiftScheduleValidator {
        var rules: [any ShiftScheduleRule]

        init(rules: [any ShiftScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftSchedule]) -> [String: [String]] {
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

    static func defaultShiftScheduleValidator() -> ShiftScheduleValidator {
        return ShiftScheduleValidator(
            rules: [
                ShiftScheduleThresholdRangeRule(min: 9.9, max: 368.0),
                ShiftScheduleRequiredReviewerRule(message: "shift schedule needs this field"),
                ShiftScheduleCodePrefixRule(prefix: "X"),
                ShiftScheduleRefillsRangeRule(min: 32, max: 255),
                ShiftScheduleLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
