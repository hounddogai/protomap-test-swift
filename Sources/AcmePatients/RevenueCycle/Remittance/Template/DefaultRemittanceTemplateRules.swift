import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance template must pass. Check returns its problems, or none.
    protocol DefaultRemittanceTemplateRule {
        func check(_ item: DefaultRemittanceTemplate) -> [String]
    }

    final class DefaultRemittanceTemplatePriorityRangeRule: DefaultRemittanceTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultRemittanceTemplateCodeLengthRule: DefaultRemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceTemplateTimezoneLengthRule: DefaultRemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceTemplateUpdatedAtRangeRule: DefaultRemittanceTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultRemittanceTemplateCreatedAtRangeRule: DefaultRemittanceTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultRemittanceTemplateRequiredReviewerRule: DefaultRemittanceTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance template.
    final class DefaultRemittanceTemplateValidator {
        var rules: [any DefaultRemittanceTemplateRule]

        init(rules: [any DefaultRemittanceTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceTemplate) -> [String] {
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

        func requireValid(_ item: DefaultRemittanceTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceTemplate]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceTemplateValidator() -> DefaultRemittanceTemplateValidator {
        return DefaultRemittanceTemplateValidator(
            rules: [
                DefaultRemittanceTemplatePriorityRangeRule(min: 80, max: 255),
                DefaultRemittanceTemplateCodeLengthRule(maxLength: 86400),
                DefaultRemittanceTemplateTimezoneLengthRule(maxLength: 120),
                DefaultRemittanceTemplateUpdatedAtRangeRule(min: 80, max: 1000),
                DefaultRemittanceTemplateCreatedAtRangeRule(min: 255, max: 3600),
                DefaultRemittanceTemplateRequiredReviewerRule(message: "default remittance template needs this field"),
            ]
        )
    }
}
