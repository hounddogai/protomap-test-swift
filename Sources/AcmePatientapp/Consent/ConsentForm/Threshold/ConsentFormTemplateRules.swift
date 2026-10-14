import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form template must pass. Check returns its problems, or none.
    protocol ConsentFormTemplateRule {
        func check(_ item: ConsentFormTemplate) -> [String]
    }

    final class ConsentFormTemplateVisibleGuardRule: ConsentFormTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ConsentFormTemplate) -> [String] {
            if item.visible && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ConsentFormTemplateCodePrefixRule: ConsentFormTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormTemplateRequiredTitleRule: ConsentFormTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormTemplateRequiredPatientRefRule: ConsentFormTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormTemplate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form template.
    final class ConsentFormTemplateValidator {
        var rules: [any ConsentFormTemplateRule]

        init(rules: [any ConsentFormTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormTemplate]) -> [String: [String]] {
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

    static func defaultConsentFormTemplateValidator() -> ConsentFormTemplateValidator {
        return ConsentFormTemplateValidator(
            rules: [
                ConsentFormTemplateVisibleGuardRule(limit: 80),
                ConsentFormTemplateCodePrefixRule(prefix: "REF"),
                ConsentFormTemplateRequiredTitleRule(message: "consent form template needs an entry"),
                ConsentFormTemplateRequiredPatientRefRule(message: "consent form template needs a value"),
            ]
        )
    }
}
