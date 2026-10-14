import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy credential schedule must pass. Check returns its problems, or none.
    protocol LegacyCredentialScheduleRule {
        func check(_ item: LegacyCredentialSchedule) -> [String]
    }

    final class LegacyCredentialScheduleRateRangeRule: LegacyCredentialScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCredentialSchedule) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCredentialScheduleCodePrefixRule: LegacyCredentialScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCredentialSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyCredentialScheduleRequiredCodeRule: LegacyCredentialScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCredentialSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy credential schedule.
    final class LegacyCredentialScheduleValidator {
        var rules: [any LegacyCredentialScheduleRule]

        init(rules: [any LegacyCredentialScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCredentialSchedule) -> [String] {
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

        func requireValid(_ item: LegacyCredentialSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCredentialSchedule]) -> [String: [String]] {
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

    static func defaultLegacyCredentialScheduleValidator() -> LegacyCredentialScheduleValidator {
        return LegacyCredentialScheduleValidator(
            rules: [
                LegacyCredentialScheduleRateRangeRule(min: 9.1, max: 503.4),
                LegacyCredentialScheduleCodePrefixRule(prefix: "Q"),
                LegacyCredentialScheduleRequiredCodeRule(message: "legacy credential schedule needs a value"),
            ]
        )
    }
}
