import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert template must pass. Check returns its problems, or none.
    protocol AlertTemplateRule {
        func check(_ item: AlertTemplate) -> [String]
    }

    final class AlertTemplateCodePrefixRule: AlertTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertTemplateRequiredCodeRule: AlertTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertTemplateRequiredNameRule: AlertTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert template.
    final class AlertTemplateValidator {
        var rules: [any AlertTemplateRule]

        init(rules: [any AlertTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertTemplate) -> [String] {
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

        func requireValid(_ item: AlertTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertTemplate]) -> [String: [String]] {
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

    static func defaultAlertTemplateValidator() -> AlertTemplateValidator {
        return AlertTemplateValidator(
            rules: [
                AlertTemplateCodePrefixRule(prefix: "OPS"),
                AlertTemplateRequiredCodeRule(message: "alert template needs a value"),
                AlertTemplateRequiredNameRule(message: "alert template needs an entry"),
            ]
        )
    }
}
