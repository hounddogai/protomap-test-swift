import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation preference must pass. Check returns its problems, or none.
    protocol IsolationPreferenceRule {
        func check(_ item: IsolationPreference) -> [String]
    }

    final class IsolationPreferenceRequiredUnitRule: IsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPreference) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationPreferenceRequiredCodeRule: IsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationPreferenceUnitLengthRule: IsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationPreference) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationPreferenceLabelLengthRule: IsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationPreferenceRequiredTimezoneRule: IsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPreference) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation preference.
    final class IsolationPreferenceValidator {
        var rules: [any IsolationPreferenceRule]

        init(rules: [any IsolationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationPreference]) -> [String: [String]] {
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

    static func defaultIsolationPreferenceValidator() -> IsolationPreferenceValidator {
        return IsolationPreferenceValidator(
            rules: [
                IsolationPreferenceRequiredUnitRule(message: "isolation preference needs an entry"),
                IsolationPreferenceRequiredCodeRule(message: "isolation preference needs an entry"),
                IsolationPreferenceUnitLengthRule(maxLength: 16),
                IsolationPreferenceLabelLengthRule(maxLength: 80),
                IsolationPreferenceRequiredTimezoneRule(message: "isolation preference needs an entry"),
            ]
        )
    }
}
