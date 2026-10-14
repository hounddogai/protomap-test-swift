import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix rollup must pass. Check returns its problems, or none.
    protocol SkillMixRollupRule {
        func check(_ item: SkillMixRollup) -> [String]
    }

    final class SkillMixRollupVersionRangeRule: SkillMixRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixRollup) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixRollupAllowedCodeRule: SkillMixRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class SkillMixRollupRequiredCodeRule: SkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixRollupCodePrefixRule: SkillMixRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixRollupNameLengthRule: SkillMixRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix rollup.
    final class SkillMixRollupValidator {
        var rules: [any SkillMixRollupRule]

        init(rules: [any SkillMixRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixRollup]) -> [String: [String]] {
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

    static func defaultSkillMixRollupValidator() -> SkillMixRollupValidator {
        return SkillMixRollupValidator(
            rules: [
                SkillMixRollupVersionRangeRule(min: 80, max: 1000),
                SkillMixRollupAllowedCodeRule(allowed: ["seasonal", "fallback"]),
                SkillMixRollupRequiredCodeRule(message: "skill mix rollup needs an entry"),
                SkillMixRollupCodePrefixRule(prefix: "REF"),
                SkillMixRollupNameLengthRule(maxLength: 32),
            ]
        )
    }
}
