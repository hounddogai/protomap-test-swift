import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal eligibility template must pass. Check returns its problems, or none.
    protocol SeasonalEligibilityTemplateRule {
        func check(_ item: SeasonalEligibilityTemplate) -> [String]
    }

    final class SeasonalEligibilityTemplateRequiredNameRule: SeasonalEligibilityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalEligibilityTemplateContactEmailLengthRule: SeasonalEligibilityTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityTemplate) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityTemplateAllowedNameRule: SeasonalEligibilityTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalEligibilityTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class SeasonalEligibilityTemplateRequiredCodeRule: SeasonalEligibilityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal eligibility template.
    final class SeasonalEligibilityTemplateValidator {
        var rules: [any SeasonalEligibilityTemplateRule]

        init(rules: [any SeasonalEligibilityTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalEligibilityTemplate) -> [String] {
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

        func requireValid(_ item: SeasonalEligibilityTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalEligibilityTemplate]) -> [String: [String]] {
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

    static func defaultSeasonalEligibilityTemplateValidator() -> SeasonalEligibilityTemplateValidator {
        return SeasonalEligibilityTemplateValidator(
            rules: [
                SeasonalEligibilityTemplateRequiredNameRule(message: "seasonal eligibility template needs a value"),
                SeasonalEligibilityTemplateContactEmailLengthRule(maxLength: 80),
                SeasonalEligibilityTemplateAllowedNameRule(allowed: []),
                SeasonalEligibilityTemplateRequiredCodeRule(message: "seasonal eligibility template needs this field"),
            ]
        )
    }
}
