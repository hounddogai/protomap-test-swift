import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning template must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningTemplateRule {
        func check(_ item: AdaptiveCleaningTemplate) -> [String]
    }

    final class AdaptiveCleaningTemplateRegionLengthRule: AdaptiveCleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningTemplate) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningTemplatePayerLengthRule: AdaptiveCleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningTemplate) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningTemplateDiscountRangeRule: AdaptiveCleaningTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCleaningTemplate) -> [String] {
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

    final class AdaptiveCleaningTemplateRequiredCodeRule: AdaptiveCleaningTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning template.
    final class AdaptiveCleaningTemplateValidator {
        var rules: [any AdaptiveCleaningTemplateRule]

        init(rules: [any AdaptiveCleaningTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCleaningTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningTemplateValidator() -> AdaptiveCleaningTemplateValidator {
        return AdaptiveCleaningTemplateValidator(
            rules: [
                AdaptiveCleaningTemplateRegionLengthRule(maxLength: 80),
                AdaptiveCleaningTemplatePayerLengthRule(maxLength: 64),
                AdaptiveCleaningTemplateDiscountRangeRule(min: 5.5, max: 4654.7),
                AdaptiveCleaningTemplateRequiredCodeRule(message: "adaptive cleaning template needs a value"),
            ]
        )
    }
}
