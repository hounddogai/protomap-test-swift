import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted skill mix milestone must pass. Check returns its problems, or none.
    protocol WeightedSkillMixMilestoneRule {
        func check(_ item: WeightedSkillMixMilestone) -> [String]
    }

    final class WeightedSkillMixMilestoneAllowedNameRule: WeightedSkillMixMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedSkillMixMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class WeightedSkillMixMilestoneRequiredCodeRule: WeightedSkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSkillMixMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSkillMixMilestoneCodePrefixRule: WeightedSkillMixMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedSkillMixMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted skill mix milestone.
    final class WeightedSkillMixMilestoneValidator {
        var rules: [any WeightedSkillMixMilestoneRule]

        init(rules: [any WeightedSkillMixMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSkillMixMilestone) -> [String] {
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

        func requireValid(_ item: WeightedSkillMixMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSkillMixMilestone]) -> [String: [String]] {
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

    static func defaultWeightedSkillMixMilestoneValidator() -> WeightedSkillMixMilestoneValidator {
        return WeightedSkillMixMilestoneValidator(
            rules: [
                WeightedSkillMixMilestoneAllowedNameRule(allowed: ["pending", "lenient", "manual"]),
                WeightedSkillMixMilestoneRequiredCodeRule(message: "weighted skill mix milestone needs this field"),
                WeightedSkillMixMilestoneCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
