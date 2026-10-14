import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory template must pass. Check returns its problems, or none.
    protocol InventoryTemplateRule {
        func check(_ item: InventoryTemplate) -> [String]
    }

    final class InventoryTemplateRequiredCodeRule: InventoryTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryTemplateLabelLengthRule: InventoryTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryTemplateTitleLengthRule: InventoryTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryTemplateDurationMinutesRangeRule: InventoryTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryTemplate) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryTemplateCategoryLengthRule: InventoryTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryTemplate) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryTemplateCodePrefixRule: InventoryTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory template.
    final class InventoryTemplateValidator {
        var rules: [any InventoryTemplateRule]

        init(rules: [any InventoryTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryTemplate]) -> [String: [String]] {
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

    static func defaultInventoryTemplateValidator() -> InventoryTemplateValidator {
        return InventoryTemplateValidator(
            rules: [
                InventoryTemplateRequiredCodeRule(message: "inventory template needs an entry"),
                InventoryTemplateLabelLengthRule(maxLength: 32),
                InventoryTemplateTitleLengthRule(maxLength: 3600),
                InventoryTemplateDurationMinutesRangeRule(min: 80, max: 3600),
                InventoryTemplateCategoryLengthRule(maxLength: 3600),
                InventoryTemplateCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
