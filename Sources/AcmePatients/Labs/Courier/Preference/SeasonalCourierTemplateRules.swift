import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal courier template must pass. Check returns its problems, or none.
    protocol SeasonalCourierTemplateRule {
        func check(_ item: SeasonalCourierTemplate) -> [String]
    }

    final class SeasonalCourierTemplateRequiredCodeRule: SeasonalCourierTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCourierTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCourierTemplateRateRangeRule: SeasonalCourierTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierTemplate) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCourierTemplateCostRangeRule: SeasonalCourierTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierTemplate) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCourierTemplateCodeLengthRule: SeasonalCourierTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal courier template.
    final class SeasonalCourierTemplateValidator {
        var rules: [any SeasonalCourierTemplateRule]

        init(rules: [any SeasonalCourierTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCourierTemplate) -> [String] {
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

        func requireValid(_ item: SeasonalCourierTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCourierTemplate]) -> [String: [String]] {
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

    static func defaultSeasonalCourierTemplateValidator() -> SeasonalCourierTemplateValidator {
        return SeasonalCourierTemplateValidator(
            rules: [
                SeasonalCourierTemplateRequiredCodeRule(message: "seasonal courier template needs this field"),
                SeasonalCourierTemplateRateRangeRule(min: 7.6, max: 3075.6),
                SeasonalCourierTemplateCostRangeRule(min: 7.1, max: 287.4),
                SeasonalCourierTemplateCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
