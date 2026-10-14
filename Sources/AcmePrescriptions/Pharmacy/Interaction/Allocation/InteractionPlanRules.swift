import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction plan must pass. Check returns its problems, or none.
    protocol InteractionPlanRule {
        func check(_ item: InteractionPlan) -> [String]
    }

    final class InteractionPlanRequiredDescriptionRule: InteractionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionPlan) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionPlanRequiredCodeRule: InteractionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionPlanThresholdRangeRule: InteractionPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionPlan) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionPlanDescriptionLengthRule: InteractionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionPlan) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction plan.
    final class InteractionPlanValidator {
        var rules: [any InteractionPlanRule]

        init(rules: [any InteractionPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionPlan) -> [String] {
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

        func requireValid(_ item: InteractionPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionPlan]) -> [String: [String]] {
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

    static func defaultInteractionPlanValidator() -> InteractionPlanValidator {
        return InteractionPlanValidator(
            rules: [
                InteractionPlanRequiredDescriptionRule(message: "interaction plan needs this field"),
                InteractionPlanRequiredCodeRule(message: "interaction plan needs a value"),
                InteractionPlanThresholdRangeRule(min: 6.4, max: 485.6),
                InteractionPlanDescriptionLengthRule(maxLength: 120),
            ]
        )
    }
}
