import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted float pool template must pass. Check returns its problems, or none.
    protocol WeightedFloatPoolTemplateRule {
        func check(_ item: WeightedFloatPoolTemplate) -> [String]
    }

    final class WeightedFloatPoolTemplateRequiredSummaryRule: WeightedFloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFloatPoolTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFloatPoolTemplateRequiredBedRule: WeightedFloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFloatPoolTemplate) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFloatPoolTemplateNameLengthRule: WeightedFloatPoolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFloatPoolTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFloatPoolTemplateCeilingRangeRule: WeightedFloatPoolTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFloatPoolTemplate) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedFloatPoolTemplateRequiredNameRule: WeightedFloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFloatPoolTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted float pool template.
    final class WeightedFloatPoolTemplateValidator {
        var rules: [any WeightedFloatPoolTemplateRule]

        init(rules: [any WeightedFloatPoolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFloatPoolTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedFloatPoolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFloatPoolTemplate]) -> [String: [String]] {
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

    static func defaultWeightedFloatPoolTemplateValidator() -> WeightedFloatPoolTemplateValidator {
        return WeightedFloatPoolTemplateValidator(
            rules: [
                WeightedFloatPoolTemplateRequiredSummaryRule(message: "weighted float pool template needs an entry"),
                WeightedFloatPoolTemplateRequiredBedRule(message: "weighted float pool template needs a value"),
                WeightedFloatPoolTemplateNameLengthRule(maxLength: 32),
                WeightedFloatPoolTemplateCeilingRangeRule(min: 6.0, max: 2738.0),
                WeightedFloatPoolTemplateRequiredNameRule(message: "weighted float pool template needs a value"),
            ]
        )
    }
}
