import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary skill mix preference must pass. Check returns its problems, or none.
    protocol PrimarySkillMixPreferenceRule {
        func check(_ item: PrimarySkillMixPreference) -> [String]
    }

    final class PrimarySkillMixPreferenceCodeLengthRule: PrimarySkillMixPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySkillMixPreferenceRequiredSourceRule: PrimarySkillMixPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySkillMixPreferenceCodePrefixRule: PrimarySkillMixPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimarySkillMixPreferenceScoreRangeRule: PrimarySkillMixPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimarySkillMixPreferenceCopayRangeRule: PrimarySkillMixPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimarySkillMixPreferenceAllowedCodeRule: PrimarySkillMixPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySkillMixPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a primary skill mix preference.
    final class PrimarySkillMixPreferenceValidator {
        var rules: [any PrimarySkillMixPreferenceRule]

        init(rules: [any PrimarySkillMixPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySkillMixPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySkillMixPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySkillMixPreference]) -> [String: [String]] {
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

    static func defaultPrimarySkillMixPreferenceValidator() -> PrimarySkillMixPreferenceValidator {
        return PrimarySkillMixPreferenceValidator(
            rules: [
                PrimarySkillMixPreferenceCodeLengthRule(maxLength: 120),
                PrimarySkillMixPreferenceRequiredSourceRule(message: "primary skill mix preference needs a value"),
                PrimarySkillMixPreferenceCodePrefixRule(prefix: "Q"),
                PrimarySkillMixPreferenceScoreRangeRule(min: 3.9, max: 1372.0),
                PrimarySkillMixPreferenceCopayRangeRule(min: 3.5, max: 1655.9),
                PrimarySkillMixPreferenceAllowedCodeRule(allowed: ["weighted", "regional"]),
            ]
        )
    }
}
