import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix mapping must pass. Check returns its problems, or none.
    protocol SkillMixMappingRule {
        func check(_ item: SkillMixMapping) -> [String]
    }

    final class SkillMixMappingCodeLengthRule: SkillMixMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixMappingAllowedCodeRule: SkillMixMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class SkillMixMappingLabelLengthRule: SkillMixMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixMappingCodePrefixRule: SkillMixMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix mapping.
    final class SkillMixMappingValidator {
        var rules: [any SkillMixMappingRule]

        init(rules: [any SkillMixMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixMapping) -> [String] {
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

        func requireValid(_ item: SkillMixMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixMapping]) -> [String: [String]] {
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

    static func defaultSkillMixMappingValidator() -> SkillMixMappingValidator {
        return SkillMixMappingValidator(
            rules: [
                SkillMixMappingCodeLengthRule(maxLength: 80),
                SkillMixMappingAllowedCodeRule(allowed: []),
                SkillMixMappingLabelLengthRule(maxLength: 3600),
                SkillMixMappingCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
