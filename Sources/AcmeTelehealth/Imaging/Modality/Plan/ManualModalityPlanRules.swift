import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual modality plan must pass. Check returns its problems, or none.
    protocol ManualModalityPlanRule {
        func check(_ item: ManualModalityPlan) -> [String]
    }

    final class ManualModalityPlanCodeLengthRule: ManualModalityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualModalityPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualModalityPlanMarginRangeRule: ManualModalityPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualModalityPlan) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualModalityPlanRequiredCategoryRule: ManualModalityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityPlan) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualModalityPlanRequiredTitleRule: ManualModalityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualModalityPlanRequiredLocaleRule: ManualModalityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualModalityPlan) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual modality plan.
    final class ManualModalityPlanValidator {
        var rules: [any ManualModalityPlanRule]

        init(rules: [any ManualModalityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualModalityPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualModalityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualModalityPlan]) -> [String: [String]] {
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

    static func defaultManualModalityPlanValidator() -> ManualModalityPlanValidator {
        return ManualModalityPlanValidator(
            rules: [
                ManualModalityPlanCodeLengthRule(maxLength: 3600),
                ManualModalityPlanMarginRangeRule(min: 5.0, max: 581.5),
                ManualModalityPlanRequiredCategoryRule(message: "manual modality plan needs a value"),
                ManualModalityPlanRequiredTitleRule(message: "manual modality plan needs a value"),
                ManualModalityPlanRequiredLocaleRule(message: "manual modality plan needs an entry"),
            ]
        )
    }
}
