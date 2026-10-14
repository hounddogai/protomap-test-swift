import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy result schedule must pass. Check returns its problems, or none.
    protocol LegacyResultScheduleRule {
        func check(_ item: LegacyResultSchedule) -> [String]
    }

    final class LegacyResultScheduleAttemptsRangeRule: LegacyResultScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultSchedule) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyResultScheduleRequiredPhoneRule: LegacyResultScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultSchedule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyResultScheduleAllowedPhoneRule: LegacyResultScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyResultSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy result schedule.
    final class LegacyResultScheduleValidator {
        var rules: [any LegacyResultScheduleRule]

        init(rules: [any LegacyResultScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyResultSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyResultSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyResultSchedule]) -> [String: [String]] {
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

    static func defaultLegacyResultScheduleValidator() -> LegacyResultScheduleValidator {
        return LegacyResultScheduleValidator(
            rules: [
                LegacyResultScheduleAttemptsRangeRule(min: 120, max: 1000),
                LegacyResultScheduleRequiredPhoneRule(message: "legacy result schedule needs a value"),
                LegacyResultScheduleAllowedPhoneRule(allowed: ["seasonal", "primary", "seasonal"]),
            ]
        )
    }
}
