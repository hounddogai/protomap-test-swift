import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual order set template must pass. Check returns its problems, or none.
    protocol ManualOrderSetTemplateRule {
        func check(_ item: ManualOrderSetTemplate) -> [String]
    }

    final class ManualOrderSetTemplateDosageMgRangeRule: ManualOrderSetTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualOrderSetTemplate) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualOrderSetTemplateLabelLengthRule: ManualOrderSetTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOrderSetTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOrderSetTemplateRequiredUnitRule: ManualOrderSetTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOrderSetTemplate) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual order set template.
    final class ManualOrderSetTemplateValidator {
        var rules: [any ManualOrderSetTemplateRule]

        init(rules: [any ManualOrderSetTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOrderSetTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualOrderSetTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOrderSetTemplate]) -> [String: [String]] {
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

    static func defaultManualOrderSetTemplateValidator() -> ManualOrderSetTemplateValidator {
        return ManualOrderSetTemplateValidator(
            rules: [
                ManualOrderSetTemplateDosageMgRangeRule(min: 7.3, max: 3998.8),
                ManualOrderSetTemplateLabelLengthRule(maxLength: 255),
                ManualOrderSetTemplateRequiredUnitRule(message: "manual order set template needs this field"),
            ]
        )
    }
}
