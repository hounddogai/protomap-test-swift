import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled goal preference must pass. Check returns its problems, or none.
    protocol ScheduledGoalPreferenceRule {
        func check(_ item: ScheduledGoalPreference) -> [String]
    }

    final class ScheduledGoalPreferenceWeightRangeRule: ScheduledGoalPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledGoalPreference) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledGoalPreferenceCodePrefixRule: ScheduledGoalPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledGoalPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledGoalPreferenceRequiredTimezoneRule: ScheduledGoalPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalPreference) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled goal preference.
    final class ScheduledGoalPreferenceValidator {
        var rules: [any ScheduledGoalPreferenceRule]

        init(rules: [any ScheduledGoalPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledGoalPreference) -> [String] {
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

        func requireValid(_ item: ScheduledGoalPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledGoalPreference]) -> [String: [String]] {
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

    static func defaultScheduledGoalPreferenceValidator() -> ScheduledGoalPreferenceValidator {
        return ScheduledGoalPreferenceValidator(
            rules: [
                ScheduledGoalPreferenceWeightRangeRule(min: 4.9, max: 1779.1),
                ScheduledGoalPreferenceCodePrefixRule(prefix: "REF"),
                ScheduledGoalPreferenceRequiredTimezoneRule(message: "scheduled goal preference needs this field"),
            ]
        )
    }
}
