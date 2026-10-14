import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered language template must pass. Check returns its problems, or none.
    protocol TieredLanguageTemplateRule {
        func check(_ item: TieredLanguageTemplate) -> [String]
    }

    final class TieredLanguageTemplateAllowedCodeRule: TieredLanguageTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class TieredLanguageTemplateWeightRangeRule: TieredLanguageTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredLanguageTemplateRequiredCodeRule: TieredLanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredLanguageTemplateRequiredTitleRule: TieredLanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredLanguageTemplateDiscountRangeRule: TieredLanguageTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredLanguageTemplateRatioRangeRule: TieredLanguageTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredLanguageTemplate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered language template.
    final class TieredLanguageTemplateValidator {
        var rules: [any TieredLanguageTemplateRule]

        init(rules: [any TieredLanguageTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredLanguageTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredLanguageTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredLanguageTemplate]) -> [String: [String]] {
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

    static func defaultTieredLanguageTemplateValidator() -> TieredLanguageTemplateValidator {
        return TieredLanguageTemplateValidator(
            rules: [
                TieredLanguageTemplateAllowedCodeRule(allowed: ["strict", "lenient"]),
                TieredLanguageTemplateWeightRangeRule(min: 2.5, max: 1713.8),
                TieredLanguageTemplateRequiredCodeRule(message: "tiered language template needs an entry"),
                TieredLanguageTemplateRequiredTitleRule(message: "tiered language template needs this field"),
                TieredLanguageTemplateDiscountRangeRule(min: 5.9, max: 4243.3),
                TieredLanguageTemplateRatioRangeRule(min: 4.0, max: 4673.1),
            ]
        )
    }
}
