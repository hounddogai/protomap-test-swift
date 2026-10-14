import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix override must pass. Check returns its problems, or none.
    protocol SkillMixOverrideRule {
        func check(_ item: SkillMixOverride) -> [String]
    }

    final class SkillMixOverrideAcuityRangeRule: SkillMixOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixOverride) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixOverrideCodePrefixRule: SkillMixOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixOverrideRevisionRangeRule: SkillMixOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixOverride) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixOverrideAllowedCodeRule: SkillMixOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix override.
    final class SkillMixOverrideValidator {
        var rules: [any SkillMixOverrideRule]

        init(rules: [any SkillMixOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixOverride) -> [String] {
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

        func requireValid(_ item: SkillMixOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixOverride]) -> [String: [String]] {
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

    static func defaultSkillMixOverrideValidator() -> SkillMixOverrideValidator {
        return SkillMixOverrideValidator(
            rules: [
                SkillMixOverrideAcuityRangeRule(min: 32, max: 64),
                SkillMixOverrideCodePrefixRule(prefix: "REF"),
                SkillMixOverrideRevisionRangeRule(min: 16, max: 255),
                SkillMixOverrideAllowedCodeRule(allowed: ["primary"]),
            ]
        )
    }
}
