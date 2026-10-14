import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix score must pass. Check returns its problems, or none.
    protocol SkillMixScoreRule {
        func check(_ item: SkillMixScore) -> [String]
    }

    final class SkillMixScoreCodePrefixRule: SkillMixScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixScoreAmountRangeRule: SkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixScore) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixScoreRatioRangeRule: SkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixScore) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixScoreRequiredCategoryRule: SkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixScore) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixScoreAllowedWardRule: SkillMixScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix score.
    final class SkillMixScoreValidator {
        var rules: [any SkillMixScoreRule]

        init(rules: [any SkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixScore]) -> [String: [String]] {
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

    static func defaultSkillMixScoreValidator() -> SkillMixScoreValidator {
        return SkillMixScoreValidator(
            rules: [
                SkillMixScoreCodePrefixRule(prefix: "OPS"),
                SkillMixScoreAmountRangeRule(min: 2.3, max: 434.8),
                SkillMixScoreRatioRangeRule(min: 2.0, max: 2312.7),
                SkillMixScoreRequiredCategoryRule(message: "skill mix score needs an entry"),
                SkillMixScoreAllowedWardRule(allowed: ["manual"]),
            ]
        )
    }
}
