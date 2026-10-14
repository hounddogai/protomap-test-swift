import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling isolation preference must pass. Check returns its problems, or none.
    protocol RollingIsolationPreferenceRule {
        func check(_ item: RollingIsolationPreference) -> [String]
    }

    final class RollingIsolationPreferenceLocaleLengthRule: RollingIsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingIsolationPreference) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingIsolationPreferencePriorityRangeRule: RollingIsolationPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingIsolationPreference) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingIsolationPreferenceRequiredNameRule: RollingIsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingIsolationPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingIsolationPreferenceCodeLengthRule: RollingIsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingIsolationPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling isolation preference.
    final class RollingIsolationPreferenceValidator {
        var rules: [any RollingIsolationPreferenceRule]

        init(rules: [any RollingIsolationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingIsolationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingIsolationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingIsolationPreference]) -> [String: [String]] {
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

    static func defaultRollingIsolationPreferenceValidator() -> RollingIsolationPreferenceValidator {
        return RollingIsolationPreferenceValidator(
            rules: [
                RollingIsolationPreferenceLocaleLengthRule(maxLength: 80),
                RollingIsolationPreferencePriorityRangeRule(min: 80, max: 1000),
                RollingIsolationPreferenceRequiredNameRule(message: "rolling isolation preference needs a value"),
                RollingIsolationPreferenceCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
