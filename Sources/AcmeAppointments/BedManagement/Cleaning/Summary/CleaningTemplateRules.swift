import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning template must pass. Check returns its problems, or none.
    protocol CleaningTemplateRule {
        func check(_ item: CleaningTemplate) -> [String]
    }

    final class CleaningTemplateCapacityRangeRule: CleaningTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningTemplate) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningTemplateRatioRangeRule: CleaningTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningTemplate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningTemplateCurrencyLengthRule: CleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningTemplate) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningTemplateLabelLengthRule: CleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningTemplateRequiredCurrencyRule: CleaningTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningTemplate) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningTemplateRequiredCodeRule: CleaningTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning template.
    final class CleaningTemplateValidator {
        var rules: [any CleaningTemplateRule]

        init(rules: [any CleaningTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningTemplate]) -> [String: [String]] {
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

    static func defaultCleaningTemplateValidator() -> CleaningTemplateValidator {
        return CleaningTemplateValidator(
            rules: [
                CleaningTemplateCapacityRangeRule(min: 16, max: 3600),
                CleaningTemplateRatioRangeRule(min: 6.7, max: 3157.6),
                CleaningTemplateCurrencyLengthRule(maxLength: 86400),
                CleaningTemplateLabelLengthRule(maxLength: 3600),
                CleaningTemplateRequiredCurrencyRule(message: "cleaning template needs an entry"),
                CleaningTemplateRequiredCodeRule(message: "cleaning template needs a value"),
            ]
        )
    }
}
