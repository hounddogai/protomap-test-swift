import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix cycle must pass. Check returns its problems, or none.
    protocol SkillMixCycleRule {
        func check(_ item: SkillMixCycle) -> [String]
    }

    final class SkillMixCycleAllowedLabelRule: SkillMixCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class SkillMixCyclePriorityRangeRule: SkillMixCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixCycle) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixCycleCodeLengthRule: SkillMixCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixCycleCurrencyLengthRule: SkillMixCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixCycle) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixCycleBudgetRangeRule: SkillMixCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixCycle) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixCycleRequiredCurrencyRule: SkillMixCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixCycle) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix cycle.
    final class SkillMixCycleValidator {
        var rules: [any SkillMixCycleRule]

        init(rules: [any SkillMixCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixCycle) -> [String] {
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

        func requireValid(_ item: SkillMixCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixCycle]) -> [String: [String]] {
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

    static func defaultSkillMixCycleValidator() -> SkillMixCycleValidator {
        return SkillMixCycleValidator(
            rules: [
                SkillMixCycleAllowedLabelRule(allowed: ["fallback"]),
                SkillMixCyclePriorityRangeRule(min: 255, max: 86400),
                SkillMixCycleCodeLengthRule(maxLength: 86400),
                SkillMixCycleCurrencyLengthRule(maxLength: 80),
                SkillMixCycleBudgetRangeRule(min: 6.8, max: 1509.3),
                SkillMixCycleRequiredCurrencyRule(message: "skill mix cycle needs an entry"),
            ]
        )
    }
}
