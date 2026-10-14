import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix override must pass. Check returns its problems, or none.
    protocol StrictSkillMixOverrideRule {
        func check(_ item: StrictSkillMixOverride) -> [String]
    }

    final class StrictSkillMixOverrideBatchSizeRangeRule: StrictSkillMixOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictSkillMixOverrideDescriptionLengthRule: StrictSkillMixOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSkillMixOverrideRequiredNameRule: StrictSkillMixOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixOverrideArchivedGuardRule: StrictSkillMixOverrideRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            if item.archived && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class StrictSkillMixOverrideBudgetRangeRule: StrictSkillMixOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSkillMixOverrideRequiredContactEmailRule: StrictSkillMixOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixOverride) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict skill mix override.
    final class StrictSkillMixOverrideValidator {
        var rules: [any StrictSkillMixOverrideRule]

        init(rules: [any StrictSkillMixOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSkillMixOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixOverride]) -> [String: [String]] {
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

    static func defaultStrictSkillMixOverrideValidator() -> StrictSkillMixOverrideValidator {
        return StrictSkillMixOverrideValidator(
            rules: [
                StrictSkillMixOverrideBatchSizeRangeRule(min: 16, max: 80),
                StrictSkillMixOverrideDescriptionLengthRule(maxLength: 16),
                StrictSkillMixOverrideRequiredNameRule(message: "strict skill mix override needs this field"),
                StrictSkillMixOverrideArchivedGuardRule(limit: 80),
                StrictSkillMixOverrideBudgetRangeRule(min: 0.8, max: 3453.4),
                StrictSkillMixOverrideRequiredContactEmailRule(message: "strict skill mix override needs a value"),
            ]
        )
    }
}
