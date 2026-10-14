import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal float pool template must pass. Check returns its problems, or none.
    protocol SeasonalFloatPoolTemplateRule {
        func check(_ item: SeasonalFloatPoolTemplate) -> [String]
    }

    final class SeasonalFloatPoolTemplateDiscountRangeRule: SeasonalFloatPoolTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFloatPoolTemplate) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalFloatPoolTemplateRequiredCodeRule: SeasonalFloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFloatPoolTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFloatPoolTemplateRequiredLabelRule: SeasonalFloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFloatPoolTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFloatPoolTemplateLabelLengthRule: SeasonalFloatPoolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFloatPoolTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalFloatPoolTemplateCodePrefixRule: SeasonalFloatPoolTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalFloatPoolTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal float pool template.
    final class SeasonalFloatPoolTemplateValidator {
        var rules: [any SeasonalFloatPoolTemplateRule]

        init(rules: [any SeasonalFloatPoolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalFloatPoolTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalFloatPoolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalFloatPoolTemplate]) -> [String: [String]] {
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

    static func defaultSeasonalFloatPoolTemplateValidator() -> SeasonalFloatPoolTemplateValidator {
        return SeasonalFloatPoolTemplateValidator(
            rules: [
                SeasonalFloatPoolTemplateDiscountRangeRule(min: 1.9, max: 2086.1),
                SeasonalFloatPoolTemplateRequiredCodeRule(message: "seasonal float pool template needs an entry"),
                SeasonalFloatPoolTemplateRequiredLabelRule(message: "seasonal float pool template needs a value"),
                SeasonalFloatPoolTemplateLabelLengthRule(maxLength: 16),
                SeasonalFloatPoolTemplateCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
