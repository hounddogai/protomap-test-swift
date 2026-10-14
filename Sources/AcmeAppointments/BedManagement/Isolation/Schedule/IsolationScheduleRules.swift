import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation schedule must pass. Check returns its problems, or none.
    protocol IsolationScheduleRule {
        func check(_ item: IsolationSchedule) -> [String]
    }

    final class IsolationScheduleCodePrefixRule: IsolationScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationScheduleVersionRangeRule: IsolationScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationSchedule) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationScheduleRequiredCodeRule: IsolationScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSchedulePinnedGuardRule: IsolationScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: IsolationSchedule) -> [String] {
            if item.pinned && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation schedule.
    final class IsolationScheduleValidator {
        var rules: [any IsolationScheduleRule]

        init(rules: [any IsolationScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationSchedule) -> [String] {
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

        func requireValid(_ item: IsolationSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationSchedule]) -> [String: [String]] {
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

    static func defaultIsolationScheduleValidator() -> IsolationScheduleValidator {
        return IsolationScheduleValidator(
            rules: [
                IsolationScheduleCodePrefixRule(prefix: "Q"),
                IsolationScheduleVersionRangeRule(min: 80, max: 1000),
                IsolationScheduleRequiredCodeRule(message: "isolation schedule needs this field"),
                IsolationSchedulePinnedGuardRule(limit: 255),
            ]
        )
    }
}
