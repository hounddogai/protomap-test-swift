import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling statement preference must pass. Check returns its problems, or none.
    protocol RollingStatementPreferenceRule {
        func check(_ item: RollingStatementPreference) -> [String]
    }

    final class RollingStatementPreferenceRequiredLabelRule: RollingStatementPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStatementPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStatementPreferenceLabelLengthRule: RollingStatementPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStatementPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStatementPreferenceCodeLengthRule: RollingStatementPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStatementPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStatementPreferenceRequiredPayerRule: RollingStatementPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStatementPreference) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStatementPreferenceAllowedCodeRule: RollingStatementPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingStatementPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling statement preference.
    final class RollingStatementPreferenceValidator {
        var rules: [any RollingStatementPreferenceRule]

        init(rules: [any RollingStatementPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStatementPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStatementPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStatementPreference]) -> [String: [String]] {
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

    static func defaultRollingStatementPreferenceValidator() -> RollingStatementPreferenceValidator {
        return RollingStatementPreferenceValidator(
            rules: [
                RollingStatementPreferenceRequiredLabelRule(message: "rolling statement preference needs an entry"),
                RollingStatementPreferenceLabelLengthRule(maxLength: 3600),
                RollingStatementPreferenceCodeLengthRule(maxLength: 120),
                RollingStatementPreferenceRequiredPayerRule(message: "rolling statement preference needs a value"),
                RollingStatementPreferenceAllowedCodeRule(allowed: ["scheduled", "regional", "seasonal"]),
            ]
        )
    }
}
