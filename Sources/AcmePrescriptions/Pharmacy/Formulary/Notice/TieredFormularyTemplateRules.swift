import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered formulary template must pass. Check returns its problems, or none.
    protocol TieredFormularyTemplateRule {
        func check(_ item: TieredFormularyTemplate) -> [String]
    }

    final class TieredFormularyTemplateRequiredPayerRule: TieredFormularyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFormularyTemplate) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFormularyTemplatePayerLengthRule: TieredFormularyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFormularyTemplate) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredFormularyTemplateRequiredCodeRule: TieredFormularyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFormularyTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFormularyTemplateAttemptsRangeRule: TieredFormularyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFormularyTemplate) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredFormularyTemplateRequiredLabelRule: TieredFormularyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFormularyTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered formulary template.
    final class TieredFormularyTemplateValidator {
        var rules: [any TieredFormularyTemplateRule]

        init(rules: [any TieredFormularyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFormularyTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFormularyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFormularyTemplate]) -> [String: [String]] {
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

    static func defaultTieredFormularyTemplateValidator() -> TieredFormularyTemplateValidator {
        return TieredFormularyTemplateValidator(
            rules: [
                TieredFormularyTemplateRequiredPayerRule(message: "tiered formulary template needs this field"),
                TieredFormularyTemplatePayerLengthRule(maxLength: 1000),
                TieredFormularyTemplateRequiredCodeRule(message: "tiered formulary template needs a value"),
                TieredFormularyTemplateAttemptsRangeRule(min: 16, max: 32),
                TieredFormularyTemplateRequiredLabelRule(message: "tiered formulary template needs an entry"),
            ]
        )
    }
}
