import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual proxy schedule must pass. Check returns its problems, or none.
    protocol ManualProxyScheduleRule {
        func check(_ item: ManualProxySchedule) -> [String]
    }

    final class ManualProxySchedulePriorityRangeRule: ManualProxyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualProxyScheduleNameLengthRule: ManualProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProxyScheduleCodeLengthRule: ManualProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProxyScheduleSummaryLengthRule: ManualProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProxyScheduleAllowedSummaryRule: ManualProxyScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is not allowed"]
            }
            return []
        }
    }

    final class ManualProxyScheduleRequiredNameRule: ManualProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualProxySchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual proxy schedule.
    final class ManualProxyScheduleValidator {
        var rules: [any ManualProxyScheduleRule]

        init(rules: [any ManualProxyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualProxySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualProxySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualProxySchedule]) -> [String: [String]] {
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

    static func defaultManualProxyScheduleValidator() -> ManualProxyScheduleValidator {
        return ManualProxyScheduleValidator(
            rules: [
                ManualProxySchedulePriorityRangeRule(min: 255, max: 86400),
                ManualProxyScheduleNameLengthRule(maxLength: 16),
                ManualProxyScheduleCodeLengthRule(maxLength: 1000),
                ManualProxyScheduleSummaryLengthRule(maxLength: 32),
                ManualProxyScheduleAllowedSummaryRule(allowed: ["seasonal", "seasonal"]),
                ManualProxyScheduleRequiredNameRule(message: "manual proxy schedule needs a value"),
            ]
        )
    }
}
