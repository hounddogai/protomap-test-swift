import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered skill mix milestone must pass. Check returns its problems, or none.
    protocol TieredSkillMixMilestoneRule {
        func check(_ item: TieredSkillMixMilestone) -> [String]
    }

    final class TieredSkillMixMilestoneCodePrefixRule: TieredSkillMixMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSkillMixMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredSkillMixMilestoneFacilityLengthRule: TieredSkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSkillMixMilestone) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSkillMixMilestoneTitleLengthRule: TieredSkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSkillMixMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSkillMixMilestoneRequiredTitleRule: TieredSkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSkillMixMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered skill mix milestone.
    final class TieredSkillMixMilestoneValidator {
        var rules: [any TieredSkillMixMilestoneRule]

        init(rules: [any TieredSkillMixMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSkillMixMilestone) -> [String] {
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

        func requireValid(_ item: TieredSkillMixMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSkillMixMilestone]) -> [String: [String]] {
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

    static func defaultTieredSkillMixMilestoneValidator() -> TieredSkillMixMilestoneValidator {
        return TieredSkillMixMilestoneValidator(
            rules: [
                TieredSkillMixMilestoneCodePrefixRule(prefix: "REF"),
                TieredSkillMixMilestoneFacilityLengthRule(maxLength: 1000),
                TieredSkillMixMilestoneTitleLengthRule(maxLength: 80),
                TieredSkillMixMilestoneRequiredTitleRule(message: "tiered skill mix milestone needs this field"),
            ]
        )
    }
}
