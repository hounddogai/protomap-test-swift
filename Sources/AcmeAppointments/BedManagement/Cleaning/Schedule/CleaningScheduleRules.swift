import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning schedule must pass. Check returns its problems, or none.
    protocol CleaningScheduleRule {
        func check(_ item: CleaningSchedule) -> [String]
    }

    final class CleaningScheduleAllowedNameRule: CleaningScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class CleaningScheduleCodePrefixRule: CleaningScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningScheduleQuantityRangeRule: CleaningScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningSchedule) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningScheduleRequiredCodeRule: CleaningScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningScheduleCodeLengthRule: CleaningScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningScheduleRequiredNameRule: CleaningScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning schedule.
    final class CleaningScheduleValidator {
        var rules: [any CleaningScheduleRule]

        init(rules: [any CleaningScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningSchedule]) -> [String: [String]] {
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

    static func defaultCleaningScheduleValidator() -> CleaningScheduleValidator {
        return CleaningScheduleValidator(
            rules: [
                CleaningScheduleAllowedNameRule(allowed: ["default"]),
                CleaningScheduleCodePrefixRule(prefix: "ACM"),
                CleaningScheduleQuantityRangeRule(min: 120, max: 1000),
                CleaningScheduleRequiredCodeRule(message: "cleaning schedule needs this field"),
                CleaningScheduleCodeLengthRule(maxLength: 64),
                CleaningScheduleRequiredNameRule(message: "cleaning schedule needs this field"),
            ]
        )
    }
}
