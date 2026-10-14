import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive credential template must pass. Check returns its problems, or none.
    protocol AdaptiveCredentialTemplateRule {
        func check(_ item: AdaptiveCredentialTemplate) -> [String]
    }

    final class AdaptiveCredentialTemplateCodeLengthRule: AdaptiveCredentialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCredentialTemplateAllowedNameRule: AdaptiveCredentialTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class AdaptiveCredentialTemplateSummaryLengthRule: AdaptiveCredentialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCredentialTemplateRequiredSummaryRule: AdaptiveCredentialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCredentialTemplateRequiredCodeRule: AdaptiveCredentialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCredentialTemplateBedLengthRule: AdaptiveCredentialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCredentialTemplate) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive credential template.
    final class AdaptiveCredentialTemplateValidator {
        var rules: [any AdaptiveCredentialTemplateRule]

        init(rules: [any AdaptiveCredentialTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCredentialTemplate) -> [String] {
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

        func requireValid(_ item: AdaptiveCredentialTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCredentialTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveCredentialTemplateValidator() -> AdaptiveCredentialTemplateValidator {
        return AdaptiveCredentialTemplateValidator(
            rules: [
                AdaptiveCredentialTemplateCodeLengthRule(maxLength: 86400),
                AdaptiveCredentialTemplateAllowedNameRule(allowed: ["fallback"]),
                AdaptiveCredentialTemplateSummaryLengthRule(maxLength: 255),
                AdaptiveCredentialTemplateRequiredSummaryRule(message: "adaptive credential template needs a value"),
                AdaptiveCredentialTemplateRequiredCodeRule(message: "adaptive credential template needs this field"),
                AdaptiveCredentialTemplateBedLengthRule(maxLength: 80),
            ]
        )
    }
}
