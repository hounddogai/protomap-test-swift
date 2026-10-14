import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive goal preference must pass. Check returns its problems, or none.
    protocol AdaptiveGoalPreferenceRule {
        func check(_ item: AdaptiveGoalPreference) -> [String]
    }

    final class AdaptiveGoalPreferenceLimitRangeRule: AdaptiveGoalPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveGoalPreference) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveGoalPreferenceAllowedContactEmailRule: AdaptiveGoalPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveGoalPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    final class AdaptiveGoalPreferenceSourceLengthRule: AdaptiveGoalPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveGoalPreference) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveGoalPreferenceRequiredCodeRule: AdaptiveGoalPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveGoalPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveGoalPreferenceCodePrefixRule: AdaptiveGoalPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveGoalPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive goal preference.
    final class AdaptiveGoalPreferenceValidator {
        var rules: [any AdaptiveGoalPreferenceRule]

        init(rules: [any AdaptiveGoalPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveGoalPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveGoalPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveGoalPreference]) -> [String: [String]] {
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

    static func defaultAdaptiveGoalPreferenceValidator() -> AdaptiveGoalPreferenceValidator {
        return AdaptiveGoalPreferenceValidator(
            rules: [
                AdaptiveGoalPreferenceLimitRangeRule(min: 80, max: 80),
                AdaptiveGoalPreferenceAllowedContactEmailRule(allowed: []),
                AdaptiveGoalPreferenceSourceLengthRule(maxLength: 16),
                AdaptiveGoalPreferenceRequiredCodeRule(message: "adaptive goal preference needs this field"),
                AdaptiveGoalPreferenceCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
