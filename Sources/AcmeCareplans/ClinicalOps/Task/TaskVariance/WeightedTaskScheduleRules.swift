import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted task schedule must pass. Check returns its problems, or none.
    protocol WeightedTaskScheduleRule {
        func check(_ item: WeightedTaskSchedule) -> [String]
    }

    final class WeightedTaskScheduleRetriesRangeRule: WeightedTaskScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTaskSchedule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedTaskScheduleCodePrefixRule: WeightedTaskScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedTaskSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedTaskScheduleCodeLengthRule: WeightedTaskScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTaskSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted task schedule.
    final class WeightedTaskScheduleValidator {
        var rules: [any WeightedTaskScheduleRule]

        init(rules: [any WeightedTaskScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTaskSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTaskSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTaskSchedule]) -> [String: [String]] {
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

    static func defaultWeightedTaskScheduleValidator() -> WeightedTaskScheduleValidator {
        return WeightedTaskScheduleValidator(
            rules: [
                WeightedTaskScheduleRetriesRangeRule(min: 80, max: 255),
                WeightedTaskScheduleCodePrefixRule(prefix: "OPS"),
                WeightedTaskScheduleCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
