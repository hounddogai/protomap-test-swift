import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive formulary template must pass. Check returns its problems, or none.
    protocol AdaptiveFormularyTemplateRule {
        func check(_ item: AdaptiveFormularyTemplate) -> [String]
    }

    final class AdaptiveFormularyTemplateRequiredContactEmailRule: AdaptiveFormularyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyTemplate) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFormularyTemplateRequiredCodeRule: AdaptiveFormularyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFormularyTemplateGraceDaysRangeRule: AdaptiveFormularyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyTemplate) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive formulary template.
    final class AdaptiveFormularyTemplateValidator {
        var rules: [any AdaptiveFormularyTemplateRule]

        init(rules: [any AdaptiveFormularyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFormularyTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFormularyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFormularyTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveFormularyTemplateValidator() -> AdaptiveFormularyTemplateValidator {
        return AdaptiveFormularyTemplateValidator(
            rules: [
                AdaptiveFormularyTemplateRequiredContactEmailRule(
                    message: "adaptive formulary template needs an entry"
                ),
                AdaptiveFormularyTemplateRequiredCodeRule(message: "adaptive formulary template needs this field"),
                AdaptiveFormularyTemplateGraceDaysRangeRule(min: 16, max: 120),
            ]
        )
    }
}
