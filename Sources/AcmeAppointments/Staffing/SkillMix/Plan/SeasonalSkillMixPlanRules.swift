import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix plan must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixPlanRule {
        func check(_ item: SeasonalSkillMixPlan) -> [String]
    }

    final class SeasonalSkillMixPlanScoreRangeRule: SeasonalSkillMixPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixPlan) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSkillMixPlanCodePrefixRule: SeasonalSkillMixPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalSkillMixPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixPlanRequiredCodeRule: SeasonalSkillMixPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixPlanMinimumRangeRule: SeasonalSkillMixPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixPlan) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixPlanAllowedLabelRule: SeasonalSkillMixPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSkillMixPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix plan.
    final class SeasonalSkillMixPlanValidator {
        var rules: [any SeasonalSkillMixPlanRule]

        init(rules: [any SeasonalSkillMixPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixPlan) -> [String] {
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

        func requireValid(_ item: SeasonalSkillMixPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixPlan]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixPlanValidator() -> SeasonalSkillMixPlanValidator {
        return SeasonalSkillMixPlanValidator(
            rules: [
                SeasonalSkillMixPlanScoreRangeRule(min: 1.2, max: 4322.0),
                SeasonalSkillMixPlanCodePrefixRule(prefix: "X"),
                SeasonalSkillMixPlanRequiredCodeRule(message: "seasonal skill mix plan needs a value"),
                SeasonalSkillMixPlanMinimumRangeRule(min: 6.1, max: 1205.8),
                SeasonalSkillMixPlanAllowedLabelRule(allowed: ["scheduled", "weighted"]),
            ]
        )
    }
}
