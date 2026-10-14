import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional panel preference must pass. Check returns its problems, or none.
    protocol RegionalPanelPreferenceRule {
        func check(_ item: RegionalPanelPreference) -> [String]
    }

    final class RegionalPanelPreferenceCodeLengthRule: RegionalPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalPanelPreferenceRequiredCodeRule: RegionalPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPanelPreferenceRequiredLabelRule: RegionalPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPanelPreferenceCeilingRangeRule: RegionalPanelPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalPanelPreferenceEndsAtRangeRule: RegionalPanelPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalPanelPreferenceUpdatedAtRangeRule: RegionalPanelPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalPanelPreference) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional panel preference.
    final class RegionalPanelPreferenceValidator {
        var rules: [any RegionalPanelPreferenceRule]

        init(rules: [any RegionalPanelPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalPanelPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalPanelPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalPanelPreference]) -> [String: [String]] {
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

    static func defaultRegionalPanelPreferenceValidator() -> RegionalPanelPreferenceValidator {
        return RegionalPanelPreferenceValidator(
            rules: [
                RegionalPanelPreferenceCodeLengthRule(maxLength: 255),
                RegionalPanelPreferenceRequiredCodeRule(message: "regional panel preference needs a value"),
                RegionalPanelPreferenceRequiredLabelRule(message: "regional panel preference needs a value"),
                RegionalPanelPreferenceCeilingRangeRule(min: 6.7, max: 4934.7),
                RegionalPanelPreferenceEndsAtRangeRule(min: 64, max: 86400),
                RegionalPanelPreferenceUpdatedAtRangeRule(min: 16, max: 255),
            ]
        )
    }
}
