import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted claim template must pass. Check returns its problems, or none.
    protocol WeightedClaimTemplateRule {
        func check(_ item: WeightedClaimTemplate) -> [String]
    }

    final class WeightedClaimTemplateLabelLengthRule: WeightedClaimTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClaimTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClaimTemplateRequiredCodeRule: WeightedClaimTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClaimTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedClaimTemplateRequiredSummaryRule: WeightedClaimTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClaimTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted claim template.
    final class WeightedClaimTemplateValidator {
        var rules: [any WeightedClaimTemplateRule]

        init(rules: [any WeightedClaimTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClaimTemplate) -> [String] {
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

        func requireValid(_ item: WeightedClaimTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClaimTemplate]) -> [String: [String]] {
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

    static func defaultWeightedClaimTemplateValidator() -> WeightedClaimTemplateValidator {
        return WeightedClaimTemplateValidator(
            rules: [
                WeightedClaimTemplateLabelLengthRule(maxLength: 3600),
                WeightedClaimTemplateRequiredCodeRule(message: "weighted claim template needs a value"),
                WeightedClaimTemplateRequiredSummaryRule(message: "weighted claim template needs this field"),
            ]
        )
    }
}
