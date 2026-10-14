import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled skill mix rollup must pass. Check returns its problems, or none.
    protocol ScheduledSkillMixRollupRule {
        func check(_ item: ScheduledSkillMixRollup) -> [String]
    }

    final class ScheduledSkillMixRollupCodeLengthRule: ScheduledSkillMixRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledSkillMixRollupCostRangeRule: ScheduledSkillMixRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledSkillMixRollupTimezoneLengthRule: ScheduledSkillMixRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledSkillMixRollupRequiredTimezoneRule: ScheduledSkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledSkillMixRollupRequiredCodeRule: ScheduledSkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledSkillMixRollupAllowedTitleRule: ScheduledSkillMixRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledSkillMixRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled skill mix rollup.
    final class ScheduledSkillMixRollupValidator {
        var rules: [any ScheduledSkillMixRollupRule]

        init(rules: [any ScheduledSkillMixRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledSkillMixRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledSkillMixRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledSkillMixRollup]) -> [String: [String]] {
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

    static func defaultScheduledSkillMixRollupValidator() -> ScheduledSkillMixRollupValidator {
        return ScheduledSkillMixRollupValidator(
            rules: [
                ScheduledSkillMixRollupCodeLengthRule(maxLength: 16),
                ScheduledSkillMixRollupCostRangeRule(min: 6.4, max: 1869.0),
                ScheduledSkillMixRollupTimezoneLengthRule(maxLength: 120),
                ScheduledSkillMixRollupRequiredTimezoneRule(message: "scheduled skill mix rollup needs an entry"),
                ScheduledSkillMixRollupRequiredCodeRule(message: "scheduled skill mix rollup needs an entry"),
                ScheduledSkillMixRollupAllowedTitleRule(allowed: ["tiered", "regional", "manual"]),
            ]
        )
    }
}
