import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled skill mix estimate must pass. Check returns its problems, or none.
    protocol ScheduledSkillMixEstimateRule {
        func check(_ item: ScheduledSkillMixEstimate) -> [String]
    }

    final class ScheduledSkillMixEstimateAllowedCodeRule: ScheduledSkillMixEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ScheduledSkillMixEstimateDescriptionLengthRule: ScheduledSkillMixEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledSkillMixEstimateAmountRangeRule: ScheduledSkillMixEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledSkillMixEstimateRequiredLabelRule: ScheduledSkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledSkillMixEstimateCopayRangeRule: ScheduledSkillMixEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledSkillMixEstimateCodeLengthRule: ScheduledSkillMixEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSkillMixEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled skill mix estimate.
    final class ScheduledSkillMixEstimateValidator {
        var rules: [any ScheduledSkillMixEstimateRule]

        init(rules: [any ScheduledSkillMixEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledSkillMixEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledSkillMixEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledSkillMixEstimate]) -> [String: [String]] {
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

    static func defaultScheduledSkillMixEstimateValidator() -> ScheduledSkillMixEstimateValidator {
        return ScheduledSkillMixEstimateValidator(
            rules: [
                ScheduledSkillMixEstimateAllowedCodeRule(allowed: []),
                ScheduledSkillMixEstimateDescriptionLengthRule(maxLength: 16),
                ScheduledSkillMixEstimateAmountRangeRule(min: 2.7, max: 4521.0),
                ScheduledSkillMixEstimateRequiredLabelRule(message: "scheduled skill mix estimate needs this field"),
                ScheduledSkillMixEstimateCopayRangeRule(min: 6.1, max: 4411.6),
                ScheduledSkillMixEstimateCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
