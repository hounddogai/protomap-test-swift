import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language template must pass. Check returns its problems, or none.
    protocol LanguageTemplateRule {
        func check(_ item: LanguageTemplate) -> [String]
    }

    final class LanguageTemplateRequiredCategoryRule: LanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageTemplate) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageTemplateAllergyLengthRule: LanguageTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTemplate) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageTemplateRequiredAllergyRule: LanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageTemplate) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageTemplateQuantityRangeRule: LanguageTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageTemplate) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageTemplateCodeLengthRule: LanguageTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageTemplateTitleLengthRule: LanguageTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language template.
    final class LanguageTemplateValidator {
        var rules: [any LanguageTemplateRule]

        init(rules: [any LanguageTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageTemplate) -> [String] {
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

        func requireValid(_ item: LanguageTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageTemplate]) -> [String: [String]] {
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

    static func defaultLanguageTemplateValidator() -> LanguageTemplateValidator {
        return LanguageTemplateValidator(
            rules: [
                LanguageTemplateRequiredCategoryRule(message: "language template needs an entry"),
                LanguageTemplateAllergyLengthRule(maxLength: 64),
                LanguageTemplateRequiredAllergyRule(message: "language template needs a value"),
                LanguageTemplateQuantityRangeRule(min: 3600, max: 86400),
                LanguageTemplateCodeLengthRule(maxLength: 80),
                LanguageTemplateTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
