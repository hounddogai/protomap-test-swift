import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix template must pass. Check returns its problems, or none.
    protocol StrictSkillMixTemplateRule {
        func check(_ item: StrictSkillMixTemplate) -> [String]
    }

    final class StrictSkillMixTemplateTitleLengthRule: StrictSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSkillMixTemplateAttemptsRangeRule: StrictSkillMixTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSkillMixTemplateCodePrefixRule: StrictSkillMixTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSkillMixTemplateAllowedTitleRule: StrictSkillMixTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class StrictSkillMixTemplateContactEmailLengthRule: StrictSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSkillMixTemplateCodeLengthRule: StrictSkillMixTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict skill mix template.
    final class StrictSkillMixTemplateValidator {
        var rules: [any StrictSkillMixTemplateRule]

        init(rules: [any StrictSkillMixTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSkillMixTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixTemplate]) -> [String: [String]] {
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

    static func defaultStrictSkillMixTemplateValidator() -> StrictSkillMixTemplateValidator {
        return StrictSkillMixTemplateValidator(
            rules: [
                StrictSkillMixTemplateTitleLengthRule(maxLength: 80),
                StrictSkillMixTemplateAttemptsRangeRule(min: 32, max: 255),
                StrictSkillMixTemplateCodePrefixRule(prefix: "OPS"),
                StrictSkillMixTemplateAllowedTitleRule(allowed: ["strict", "weighted"]),
                StrictSkillMixTemplateContactEmailLengthRule(maxLength: 1000),
                StrictSkillMixTemplateCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
