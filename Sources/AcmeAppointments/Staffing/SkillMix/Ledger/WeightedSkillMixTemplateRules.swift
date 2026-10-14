import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted skill mix template must pass. Check returns its problems, or none.
    protocol WeightedSkillMixTemplateRule {
        func check(_ item: WeightedSkillMixTemplate) -> [String]
    }

    final class WeightedSkillMixTemplateDescriptionLengthRule: WeightedSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSkillMixTemplate) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSkillMixTemplateCodePrefixRule: WeightedSkillMixTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedSkillMixTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedSkillMixTemplateAllowedExternalRefRule: WeightedSkillMixTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedSkillMixTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is blocked"]
            }
            return []
        }
    }

    final class WeightedSkillMixTemplateCodeLengthRule: WeightedSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSkillMixTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted skill mix template.
    final class WeightedSkillMixTemplateValidator {
        var rules: [any WeightedSkillMixTemplateRule]

        init(rules: [any WeightedSkillMixTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSkillMixTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSkillMixTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSkillMixTemplate]) -> [String: [String]] {
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

    static func defaultWeightedSkillMixTemplateValidator() -> WeightedSkillMixTemplateValidator {
        return WeightedSkillMixTemplateValidator(
            rules: [
                WeightedSkillMixTemplateDescriptionLengthRule(maxLength: 255),
                WeightedSkillMixTemplateCodePrefixRule(prefix: "REF"),
                WeightedSkillMixTemplateAllowedExternalRefRule(allowed: ["weighted", "adaptive"]),
                WeightedSkillMixTemplateCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
