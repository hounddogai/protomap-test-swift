import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix adjustment must pass. Check returns its problems, or none.
    protocol SkillMixAdjustmentRule {
        func check(_ item: SkillMixAdjustment) -> [String]
    }

    final class SkillMixAdjustmentRequiredCodeRule: SkillMixAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAdjustmentLabelLengthRule: SkillMixAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixAdjustmentVisibleGuardRule: SkillMixAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SkillMixAdjustment) -> [String] {
            if item.visible && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SkillMixAdjustmentCodeLengthRule: SkillMixAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixAdjustmentQuantityRangeRule: SkillMixAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAdjustment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix adjustment.
    final class SkillMixAdjustmentValidator {
        var rules: [any SkillMixAdjustmentRule]

        init(rules: [any SkillMixAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixAdjustment) -> [String] {
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

        func requireValid(_ item: SkillMixAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixAdjustment]) -> [String: [String]] {
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

    static func defaultSkillMixAdjustmentValidator() -> SkillMixAdjustmentValidator {
        return SkillMixAdjustmentValidator(
            rules: [
                SkillMixAdjustmentRequiredCodeRule(message: "skill mix adjustment needs a value"),
                SkillMixAdjustmentLabelLengthRule(maxLength: 80),
                SkillMixAdjustmentVisibleGuardRule(limit: 1000),
                SkillMixAdjustmentCodeLengthRule(maxLength: 64),
                SkillMixAdjustmentQuantityRangeRule(min: 32, max: 255),
            ]
        )
    }
}
