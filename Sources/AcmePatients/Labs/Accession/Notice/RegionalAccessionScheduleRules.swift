import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional accession schedule must pass. Check returns its problems, or none.
    protocol RegionalAccessionScheduleRule {
        func check(_ item: RegionalAccessionSchedule) -> [String]
    }

    final class RegionalAccessionScheduleCodePrefixRule: RegionalAccessionScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAccessionSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAccessionScheduleRequiredTitleRule: RegionalAccessionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAccessionSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAccessionScheduleRateRangeRule: RegionalAccessionScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAccessionSchedule) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional accession schedule.
    final class RegionalAccessionScheduleValidator {
        var rules: [any RegionalAccessionScheduleRule]

        init(rules: [any RegionalAccessionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAccessionSchedule) -> [String] {
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

        func requireValid(_ item: RegionalAccessionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAccessionSchedule]) -> [String: [String]] {
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

    static func defaultRegionalAccessionScheduleValidator() -> RegionalAccessionScheduleValidator {
        return RegionalAccessionScheduleValidator(
            rules: [
                RegionalAccessionScheduleCodePrefixRule(prefix: "X"),
                RegionalAccessionScheduleRequiredTitleRule(message: "regional accession schedule needs a value"),
                RegionalAccessionScheduleRateRangeRule(min: 8.4, max: 2445.7),
            ]
        )
    }
}
