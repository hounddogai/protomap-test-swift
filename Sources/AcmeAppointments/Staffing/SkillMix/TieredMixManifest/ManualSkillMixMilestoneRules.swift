import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual skill mix milestone must pass. Check returns its problems, or none.
    protocol ManualSkillMixMilestoneRule {
        func check(_ item: ManualSkillMixMilestone) -> [String]
    }

    final class ManualSkillMixMilestoneRequiredCodeRule: ManualSkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSkillMixMilestoneRequiredPhoneRule: ManualSkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualSkillMixMilestonePhoneLengthRule: ManualSkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSkillMixMilestoneLabelLengthRule: ManualSkillMixMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSkillMixMilestoneAmountRangeRule: ManualSkillMixMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualSkillMixMilestoneRequiredLabelRule: ManualSkillMixMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualSkillMixMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual skill mix milestone.
    final class ManualSkillMixMilestoneValidator {
        var rules: [any ManualSkillMixMilestoneRule]

        init(rules: [any ManualSkillMixMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSkillMixMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualSkillMixMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSkillMixMilestone]) -> [String: [String]] {
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

    static func defaultManualSkillMixMilestoneValidator() -> ManualSkillMixMilestoneValidator {
        return ManualSkillMixMilestoneValidator(
            rules: [
                ManualSkillMixMilestoneRequiredCodeRule(message: "manual skill mix milestone needs an entry"),
                ManualSkillMixMilestoneRequiredPhoneRule(message: "manual skill mix milestone needs this field"),
                ManualSkillMixMilestonePhoneLengthRule(maxLength: 1000),
                ManualSkillMixMilestoneLabelLengthRule(maxLength: 3600),
                ManualSkillMixMilestoneAmountRangeRule(min: 4.4, max: 4127.3),
                ManualSkillMixMilestoneRequiredLabelRule(message: "manual skill mix milestone needs a value"),
            ]
        )
    }
}
