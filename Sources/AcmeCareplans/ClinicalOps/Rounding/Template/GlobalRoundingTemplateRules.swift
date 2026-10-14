import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global rounding template must pass. Check returns its problems, or none.
    protocol GlobalRoundingTemplateRule {
        func check(_ item: GlobalRoundingTemplate) -> [String]
    }

    final class GlobalRoundingTemplateNotesLengthRule: GlobalRoundingTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRoundingTemplateCodeLengthRule: GlobalRoundingTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRoundingTemplateBatchSizeRangeRule: GlobalRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalRoundingTemplateRequiredAllergyRule: GlobalRoundingTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRoundingTemplateRequiredCodeRule: GlobalRoundingTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRoundingTemplateAcuityRangeRule: GlobalRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRoundingTemplate) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global rounding template.
    final class GlobalRoundingTemplateValidator {
        var rules: [any GlobalRoundingTemplateRule]

        init(rules: [any GlobalRoundingTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRoundingTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalRoundingTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRoundingTemplate]) -> [String: [String]] {
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

    static func defaultGlobalRoundingTemplateValidator() -> GlobalRoundingTemplateValidator {
        return GlobalRoundingTemplateValidator(
            rules: [
                GlobalRoundingTemplateNotesLengthRule(maxLength: 16),
                GlobalRoundingTemplateCodeLengthRule(maxLength: 86400),
                GlobalRoundingTemplateBatchSizeRangeRule(min: 64, max: 86400),
                GlobalRoundingTemplateRequiredAllergyRule(message: "global rounding template needs this field"),
                GlobalRoundingTemplateRequiredCodeRule(message: "global rounding template needs a value"),
                GlobalRoundingTemplateAcuityRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
