import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional result schedule must pass. Check returns its problems, or none.
    protocol RegionalResultScheduleRule {
        func check(_ item: RegionalResultSchedule) -> [String]
    }

    final class RegionalResultScheduleCodePrefixRule: RegionalResultScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalResultSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalResultScheduleRequiredCodeRule: RegionalResultScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalResultSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalResultScheduleRequiredNameRule: RegionalResultScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalResultSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional result schedule.
    final class RegionalResultScheduleValidator {
        var rules: [any RegionalResultScheduleRule]

        init(rules: [any RegionalResultScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalResultSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalResultSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalResultSchedule]) -> [String: [String]] {
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

    static func defaultRegionalResultScheduleValidator() -> RegionalResultScheduleValidator {
        return RegionalResultScheduleValidator(
            rules: [
                RegionalResultScheduleCodePrefixRule(prefix: "X"),
                RegionalResultScheduleRequiredCodeRule(message: "regional result schedule needs an entry"),
                RegionalResultScheduleRequiredNameRule(message: "regional result schedule needs a value"),
            ]
        )
    }
}
