import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered denial template must pass. Check returns its problems, or none.
    protocol TieredDenialTemplateRule {
        func check(_ item: TieredDenialTemplate) -> [String]
    }

    final class TieredDenialTemplateDosageMgRangeRule: TieredDenialTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredDenialTemplate) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredDenialTemplateRequiredTitleRule: TieredDenialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredDenialTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredDenialTemplateAllowedTitleRule: TieredDenialTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredDenialTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered denial template.
    final class TieredDenialTemplateValidator {
        var rules: [any TieredDenialTemplateRule]

        init(rules: [any TieredDenialTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredDenialTemplate) -> [String] {
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

        func requireValid(_ item: TieredDenialTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredDenialTemplate]) -> [String: [String]] {
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

    static func defaultTieredDenialTemplateValidator() -> TieredDenialTemplateValidator {
        return TieredDenialTemplateValidator(
            rules: [
                TieredDenialTemplateDosageMgRangeRule(min: 3.5, max: 1918.4),
                TieredDenialTemplateRequiredTitleRule(message: "tiered denial template needs this field"),
                TieredDenialTemplateAllowedTitleRule(allowed: []),
            ]
        )
    }
}
