import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling worklist preference must pass. Check returns its problems, or none.
    protocol RollingWorklistPreferenceRule {
        func check(_ item: RollingWorklistPreference) -> [String]
    }

    final class RollingWorklistPreferenceAllowedPayerRule: RollingWorklistPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingWorklistPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is blocked"]
            }
            return []
        }
    }

    final class RollingWorklistPreferenceReviewerLengthRule: RollingWorklistPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWorklistPreference) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingWorklistPreferenceRequiredPayerRule: RollingWorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWorklistPreference) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWorklistPreferencePayerLengthRule: RollingWorklistPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWorklistPreference) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling worklist preference.
    final class RollingWorklistPreferenceValidator {
        var rules: [any RollingWorklistPreferenceRule]

        init(rules: [any RollingWorklistPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWorklistPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingWorklistPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWorklistPreference]) -> [String: [String]] {
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

    static func defaultRollingWorklistPreferenceValidator() -> RollingWorklistPreferenceValidator {
        return RollingWorklistPreferenceValidator(
            rules: [
                RollingWorklistPreferenceAllowedPayerRule(allowed: ["manual"]),
                RollingWorklistPreferenceReviewerLengthRule(maxLength: 64),
                RollingWorklistPreferenceRequiredPayerRule(message: "rolling worklist preference needs this field"),
                RollingWorklistPreferencePayerLengthRule(maxLength: 80),
            ]
        )
    }
}
