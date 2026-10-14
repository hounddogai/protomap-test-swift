import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy language template must pass. Check returns its problems, or none.
    protocol LegacyLanguageTemplateRule {
        func check(_ item: LegacyLanguageTemplate) -> [String]
    }

    final class LegacyLanguageTemplateTitleLengthRule: LegacyLanguageTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyLanguageTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyLanguageTemplateRequiredLocaleRule: LegacyLanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyLanguageTemplate) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyLanguageTemplateRequiredCodeRule: LegacyLanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyLanguageTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyLanguageTemplateRequiredOwnerIDRule: LegacyLanguageTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyLanguageTemplate) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy language template.
    final class LegacyLanguageTemplateValidator {
        var rules: [any LegacyLanguageTemplateRule]

        init(rules: [any LegacyLanguageTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyLanguageTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyLanguageTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyLanguageTemplate]) -> [String: [String]] {
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

    static func defaultLegacyLanguageTemplateValidator() -> LegacyLanguageTemplateValidator {
        return LegacyLanguageTemplateValidator(
            rules: [
                LegacyLanguageTemplateTitleLengthRule(maxLength: 3600),
                LegacyLanguageTemplateRequiredLocaleRule(message: "legacy language template needs a value"),
                LegacyLanguageTemplateRequiredCodeRule(message: "legacy language template needs a value"),
                LegacyLanguageTemplateRequiredOwnerIDRule(message: "legacy language template needs this field"),
            ]
        )
    }
}
