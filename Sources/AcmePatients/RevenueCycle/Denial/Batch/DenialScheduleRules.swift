import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial schedule must pass. Check returns its problems, or none.
    protocol DenialScheduleRule {
        func check(_ item: DenialSchedule) -> [String]
    }

    final class DenialScheduleCodeLengthRule: DenialScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialScheduleRevisionRangeRule: DenialScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialSchedule) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialScheduleCodePrefixRule: DenialScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial schedule.
    final class DenialScheduleValidator {
        var rules: [any DenialScheduleRule]

        init(rules: [any DenialScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialSchedule]) -> [String: [String]] {
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

    static func defaultDenialScheduleValidator() -> DenialScheduleValidator {
        return DenialScheduleValidator(
            rules: [
                DenialScheduleCodeLengthRule(maxLength: 3600),
                DenialScheduleRevisionRangeRule(min: 86400, max: 86400),
                DenialScheduleCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
