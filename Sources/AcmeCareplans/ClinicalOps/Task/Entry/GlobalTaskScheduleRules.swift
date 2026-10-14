import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global task schedule must pass. Check returns its problems, or none.
    protocol GlobalTaskScheduleRule {
        func check(_ item: GlobalTaskSchedule) -> [String]
    }

    final class GlobalTaskScheduleRequiredLabelRule: GlobalTaskScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTaskScheduleActiveGuardRule: GlobalTaskScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalTaskSchedule) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class GlobalTaskScheduleExpiresAtRangeRule: GlobalTaskScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTaskSchedule) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalTaskScheduleCodePrefixRule: GlobalTaskScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalTaskSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalTaskScheduleLabelLengthRule: GlobalTaskScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTaskSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global task schedule.
    final class GlobalTaskScheduleValidator {
        var rules: [any GlobalTaskScheduleRule]

        init(rules: [any GlobalTaskScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTaskSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalTaskSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTaskSchedule]) -> [String: [String]] {
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

    static func defaultGlobalTaskScheduleValidator() -> GlobalTaskScheduleValidator {
        return GlobalTaskScheduleValidator(
            rules: [
                GlobalTaskScheduleRequiredLabelRule(message: "global task schedule needs this field"),
                GlobalTaskScheduleActiveGuardRule(limit: 120),
                GlobalTaskScheduleExpiresAtRangeRule(min: 16, max: 3600),
                GlobalTaskScheduleCodePrefixRule(prefix: "OPS"),
                GlobalTaskScheduleLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
