import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach schedule must pass. Check returns its problems, or none.
    protocol OutreachScheduleRule {
        func check(_ item: OutreachSchedule) -> [String]
    }

    final class OutreachScheduleRequiredNameRule: OutreachScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachScheduleMaximumRangeRule: OutreachScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachSchedule) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachScheduleArchivedGuardRule: OutreachScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: OutreachSchedule) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class OutreachScheduleCodePrefixRule: OutreachScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachScheduleTimezoneLengthRule: OutreachScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachSchedule) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach schedule.
    final class OutreachScheduleValidator {
        var rules: [any OutreachScheduleRule]

        init(rules: [any OutreachScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachSchedule) -> [String] {
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

        func requireValid(_ item: OutreachSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachSchedule]) -> [String: [String]] {
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

    static func defaultOutreachScheduleValidator() -> OutreachScheduleValidator {
        return OutreachScheduleValidator(
            rules: [
                OutreachScheduleRequiredNameRule(message: "outreach schedule needs this field"),
                OutreachScheduleMaximumRangeRule(min: 1.1, max: 4750.8),
                OutreachScheduleArchivedGuardRule(limit: 1.9),
                OutreachScheduleCodePrefixRule(prefix: "OPS"),
                OutreachScheduleTimezoneLengthRule(maxLength: 80),
            ]
        )
    }
}
