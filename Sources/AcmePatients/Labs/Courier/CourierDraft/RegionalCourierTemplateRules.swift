import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional courier template must pass. Check returns its problems, or none.
    protocol RegionalCourierTemplateRule {
        func check(_ item: RegionalCourierTemplate) -> [String]
    }

    final class RegionalCourierTemplateAllowedExternalRefRule: RegionalCourierTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCourierTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is duplicated"]
            }
            return []
        }
    }

    final class RegionalCourierTemplateCodePrefixRule: RegionalCourierTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCourierTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCourierTemplateRequiredPatientRefRule: RegionalCourierTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCourierTemplate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional courier template.
    final class RegionalCourierTemplateValidator {
        var rules: [any RegionalCourierTemplateRule]

        init(rules: [any RegionalCourierTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCourierTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCourierTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCourierTemplate]) -> [String: [String]] {
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

    static func defaultRegionalCourierTemplateValidator() -> RegionalCourierTemplateValidator {
        return RegionalCourierTemplateValidator(
            rules: [
                RegionalCourierTemplateAllowedExternalRefRule(allowed: ["batched", "batched", "capped"]),
                RegionalCourierTemplateCodePrefixRule(prefix: "OPS"),
                RegionalCourierTemplateRequiredPatientRefRule(message: "regional courier template needs a value"),
            ]
        )
    }
}
