import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling panel preference must pass. Check returns its problems, or none.
    protocol RollingPanelPreferenceRule {
        func check(_ item: RollingPanelPreference) -> [String]
    }

    final class RollingPanelPreferenceRequiredBedRule: RollingPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPanelPreference) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPanelPreferenceCodePrefixRule: RollingPanelPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingPanelPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingPanelPreferenceMaximumRangeRule: RollingPanelPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPanelPreference) -> [String] {
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

    final class RollingPanelPreferenceRequiredLabelRule: RollingPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPanelPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPanelPreferenceContactEmailLengthRule: RollingPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelPreference) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelPreferenceBedLengthRule: RollingPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelPreference) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling panel preference.
    final class RollingPanelPreferenceValidator {
        var rules: [any RollingPanelPreferenceRule]

        init(rules: [any RollingPanelPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPanelPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingPanelPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPanelPreference]) -> [String: [String]] {
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

    static func defaultRollingPanelPreferenceValidator() -> RollingPanelPreferenceValidator {
        return RollingPanelPreferenceValidator(
            rules: [
                RollingPanelPreferenceRequiredBedRule(message: "rolling panel preference needs an entry"),
                RollingPanelPreferenceCodePrefixRule(prefix: "Q"),
                RollingPanelPreferenceMaximumRangeRule(min: 4.9, max: 4719.3),
                RollingPanelPreferenceRequiredLabelRule(message: "rolling panel preference needs an entry"),
                RollingPanelPreferenceContactEmailLengthRule(maxLength: 16),
                RollingPanelPreferenceBedLengthRule(maxLength: 16),
            ]
        )
    }
}
