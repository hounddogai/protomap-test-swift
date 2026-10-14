import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped skill mix slot must pass. Check returns its problems, or none.
    protocol CappedSkillMixSlotRule {
        func check(_ item: CappedSkillMixSlot) -> [String]
    }

    final class CappedSkillMixSlotCodeLengthRule: CappedSkillMixSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixSlotAllowedUnitRule: CappedSkillMixSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is unknown"]
            }
            return []
        }
    }

    final class CappedSkillMixSlotWeightRangeRule: CappedSkillMixSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedSkillMixSlotUpdatedAtRangeRule: CappedSkillMixSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedSkillMixSlotTitleLengthRule: CappedSkillMixSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixSlotRequiredTitleRule: CappedSkillMixSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedSkillMixSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped skill mix slot.
    final class CappedSkillMixSlotValidator {
        var rules: [any CappedSkillMixSlotRule]

        init(rules: [any CappedSkillMixSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSkillMixSlot) -> [String] {
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

        func requireValid(_ item: CappedSkillMixSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSkillMixSlot]) -> [String: [String]] {
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

    static func defaultCappedSkillMixSlotValidator() -> CappedSkillMixSlotValidator {
        return CappedSkillMixSlotValidator(
            rules: [
                CappedSkillMixSlotCodeLengthRule(maxLength: 1000),
                CappedSkillMixSlotAllowedUnitRule(allowed: []),
                CappedSkillMixSlotWeightRangeRule(min: 7.7, max: 1730.3),
                CappedSkillMixSlotUpdatedAtRangeRule(min: 32, max: 80),
                CappedSkillMixSlotTitleLengthRule(maxLength: 64),
                CappedSkillMixSlotRequiredTitleRule(message: "capped skill mix slot needs a value"),
            ]
        )
    }
}
