import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy skill mix milestone must pass. Check returns its problems, or none.
    protocol LegacySkillMixMilestoneRule {
        func check(_ item: LegacySkillMixMilestone) -> [String]
    }

    final class LegacySkillMixMilestoneRequiredLocaleRule: LegacySkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySkillMixMilestone) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySkillMixMilestoneCodePrefixRule: LegacySkillMixMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacySkillMixMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacySkillMixMilestoneTitleLengthRule: LegacySkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySkillMixMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySkillMixMilestoneCodeLengthRule: LegacySkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySkillMixMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy skill mix milestone.
    final class LegacySkillMixMilestoneValidator {
        var rules: [any LegacySkillMixMilestoneRule]

        init(rules: [any LegacySkillMixMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySkillMixMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacySkillMixMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySkillMixMilestone]) -> [String: [String]] {
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

    static func defaultLegacySkillMixMilestoneValidator() -> LegacySkillMixMilestoneValidator {
        return LegacySkillMixMilestoneValidator(
            rules: [
                LegacySkillMixMilestoneRequiredLocaleRule(message: "legacy skill mix milestone needs a value"),
                LegacySkillMixMilestoneCodePrefixRule(prefix: "OPS"),
                LegacySkillMixMilestoneTitleLengthRule(maxLength: 64),
                LegacySkillMixMilestoneCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
