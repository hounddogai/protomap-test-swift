import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global program preference must pass. Check returns its problems, or none.
    protocol GlobalProgramPreferenceRule {
        func check(_ item: GlobalProgramPreference) -> [String]
    }

    final class GlobalProgramPreferenceMinimumRangeRule: GlobalProgramPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalProgramPreference) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalProgramPreferenceRequiredCodeRule: GlobalProgramPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalProgramPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalProgramPreferenceTitleLengthRule: GlobalProgramPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalProgramPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global program preference.
    final class GlobalProgramPreferenceValidator {
        var rules: [any GlobalProgramPreferenceRule]

        init(rules: [any GlobalProgramPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalProgramPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalProgramPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalProgramPreference]) -> [String: [String]] {
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

    static func defaultGlobalProgramPreferenceValidator() -> GlobalProgramPreferenceValidator {
        return GlobalProgramPreferenceValidator(
            rules: [
                GlobalProgramPreferenceMinimumRangeRule(min: 3.5, max: 1190.7),
                GlobalProgramPreferenceRequiredCodeRule(message: "global program preference needs a value"),
                GlobalProgramPreferenceTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
