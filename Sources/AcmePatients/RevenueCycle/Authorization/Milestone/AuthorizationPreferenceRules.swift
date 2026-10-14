import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization preference must pass. Check returns its problems, or none.
    protocol AuthorizationPreferenceRule {
        func check(_ item: AuthorizationPreference) -> [String]
    }

    final class AuthorizationPreferenceRequiredLabelRule: AuthorizationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationPreferenceDosageMgRangeRule: AuthorizationPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationPreference) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationPreferenceCodeLengthRule: AuthorizationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationPreferenceGraceDaysRangeRule: AuthorizationPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationPreference) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization preference.
    final class AuthorizationPreferenceValidator {
        var rules: [any AuthorizationPreferenceRule]

        init(rules: [any AuthorizationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationPreference]) -> [String: [String]] {
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

    static func defaultAuthorizationPreferenceValidator() -> AuthorizationPreferenceValidator {
        return AuthorizationPreferenceValidator(
            rules: [
                AuthorizationPreferenceRequiredLabelRule(message: "authorization preference needs this field"),
                AuthorizationPreferenceDosageMgRangeRule(min: 2.4, max: 4823.9),
                AuthorizationPreferenceCodeLengthRule(maxLength: 32),
                AuthorizationPreferenceGraceDaysRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
