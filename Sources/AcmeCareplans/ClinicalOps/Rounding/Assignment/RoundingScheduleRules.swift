import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding schedule must pass. Check returns its problems, or none.
    protocol RoundingScheduleRule {
        func check(_ item: RoundingSchedule) -> [String]
    }

    final class RoundingScheduleScoreRangeRule: RoundingScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingSchedule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingScheduleCodePrefixRule: RoundingScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingScheduleCodeLengthRule: RoundingScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding schedule.
    final class RoundingScheduleValidator {
        var rules: [any RoundingScheduleRule]

        init(rules: [any RoundingScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingSchedule]) -> [String: [String]] {
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

    static func defaultRoundingScheduleValidator() -> RoundingScheduleValidator {
        return RoundingScheduleValidator(
            rules: [
                RoundingScheduleScoreRangeRule(min: 6.2, max: 2567.6),
                RoundingScheduleCodePrefixRule(prefix: "REF"),
                RoundingScheduleCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
