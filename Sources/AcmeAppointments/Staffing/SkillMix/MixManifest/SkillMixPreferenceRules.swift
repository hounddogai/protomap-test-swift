import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix preference must pass. Check returns its problems, or none.
    protocol SkillMixPreferenceRule {
        func check(_ item: SkillMixPreference) -> [String]
    }

    final class SkillMixPreferenceCodePrefixRule: SkillMixPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixPreferenceDiscountRangeRule: SkillMixPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixPreference) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixPreferenceLocaleLengthRule: SkillMixPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixPreference) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix preference.
    final class SkillMixPreferenceValidator {
        var rules: [any SkillMixPreferenceRule]

        init(rules: [any SkillMixPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixPreference]) -> [String: [String]] {
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

    static func defaultSkillMixPreferenceValidator() -> SkillMixPreferenceValidator {
        return SkillMixPreferenceValidator(
            rules: [
                SkillMixPreferenceCodePrefixRule(prefix: "X"),
                SkillMixPreferenceDiscountRangeRule(min: 3.7, max: 3608.1),
                SkillMixPreferenceLocaleLengthRule(maxLength: 120),
            ]
        )
    }
}
