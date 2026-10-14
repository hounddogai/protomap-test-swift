import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift template must pass. Check returns its problems, or none.
    protocol DefaultShiftTemplateRule {
        func check(_ item: DefaultShiftTemplate) -> [String]
    }

    final class DefaultShiftTemplateCodeLengthRule: DefaultShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultShiftTemplateRequiredSummaryRule: DefaultShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultShiftTemplateLabelLengthRule: DefaultShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultShiftTemplateDurationMinutesRangeRule: DefaultShiftTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftTemplate) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default shift template.
    final class DefaultShiftTemplateValidator {
        var rules: [any DefaultShiftTemplateRule]

        init(rules: [any DefaultShiftTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultShiftTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftTemplate]) -> [String: [String]] {
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

    static func defaultDefaultShiftTemplateValidator() -> DefaultShiftTemplateValidator {
        return DefaultShiftTemplateValidator(
            rules: [
                DefaultShiftTemplateCodeLengthRule(maxLength: 3600),
                DefaultShiftTemplateRequiredSummaryRule(message: "default shift template needs this field"),
                DefaultShiftTemplateLabelLengthRule(maxLength: 32),
                DefaultShiftTemplateDurationMinutesRangeRule(min: 80, max: 120),
            ]
        )
    }
}
