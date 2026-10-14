import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient worklist template must pass. Check returns its problems, or none.
    protocol LenientWorklistTemplateRule {
        func check(_ item: LenientWorklistTemplate) -> [String]
    }

    final class LenientWorklistTemplateLabelLengthRule: LenientWorklistTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWorklistTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientWorklistTemplateRequiredCodeRule: LenientWorklistTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWorklistTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWorklistTemplateCodeLengthRule: LenientWorklistTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWorklistTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientWorklistTemplateRequiredAllergyRule: LenientWorklistTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWorklistTemplate) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWorklistTemplateVersionRangeRule: LenientWorklistTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientWorklistTemplate) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient worklist template.
    final class LenientWorklistTemplateValidator {
        var rules: [any LenientWorklistTemplateRule]

        init(rules: [any LenientWorklistTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientWorklistTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientWorklistTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientWorklistTemplate]) -> [String: [String]] {
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

    static func defaultLenientWorklistTemplateValidator() -> LenientWorklistTemplateValidator {
        return LenientWorklistTemplateValidator(
            rules: [
                LenientWorklistTemplateLabelLengthRule(maxLength: 120),
                LenientWorklistTemplateRequiredCodeRule(message: "lenient worklist template needs a value"),
                LenientWorklistTemplateCodeLengthRule(maxLength: 3600),
                LenientWorklistTemplateRequiredAllergyRule(message: "lenient worklist template needs this field"),
                LenientWorklistTemplateVersionRangeRule(min: 255, max: 255),
            ]
        )
    }
}
