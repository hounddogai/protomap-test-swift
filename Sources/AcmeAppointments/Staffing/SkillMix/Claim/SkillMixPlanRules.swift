import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix plan must pass. Check returns its problems, or none.
    protocol SkillMixPlanRule {
        func check(_ item: SkillMixPlan) -> [String]
    }

    final class SkillMixPlanRequiredBedRule: SkillMixPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixPlanAmountRangeRule: SkillMixPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixPlan) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixPlanAllowedTimezoneRule: SkillMixPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is not allowed"]
            }
            return []
        }
    }

    final class SkillMixPlanRequiredLabelRule: SkillMixPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixPlanCodePrefixRule: SkillMixPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixPlanBedLengthRule: SkillMixPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixPlan) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix plan.
    final class SkillMixPlanValidator {
        var rules: [any SkillMixPlanRule]

        init(rules: [any SkillMixPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixPlan]) -> [String: [String]] {
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

    static func defaultSkillMixPlanValidator() -> SkillMixPlanValidator {
        return SkillMixPlanValidator(
            rules: [
                SkillMixPlanRequiredBedRule(message: "skill mix plan needs a value"),
                SkillMixPlanAmountRangeRule(min: 3.4, max: 2352.2),
                SkillMixPlanAllowedTimezoneRule(allowed: ["default"]),
                SkillMixPlanRequiredLabelRule(message: "skill mix plan needs a value"),
                SkillMixPlanCodePrefixRule(prefix: "Q"),
                SkillMixPlanBedLengthRule(maxLength: 32),
            ]
        )
    }
}
