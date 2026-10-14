import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen template must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenTemplateRule {
        func check(_ item: AdaptiveSpecimenTemplate) -> [String]
    }

    final class AdaptiveSpecimenTemplateAllowedProcedureCodeRule: AdaptiveSpecimenTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenTemplateProcedureCodeLengthRule: AdaptiveSpecimenTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenTemplateRevisionRangeRule: AdaptiveSpecimenTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenTemplateRequiredTitleRule: AdaptiveSpecimenTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenTemplateRequiredCodeRule: AdaptiveSpecimenTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenTemplateRequiredProcedureCodeRule: AdaptiveSpecimenTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenTemplate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen template.
    final class AdaptiveSpecimenTemplateValidator {
        var rules: [any AdaptiveSpecimenTemplateRule]

        init(rules: [any AdaptiveSpecimenTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSpecimenTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenTemplateValidator() -> AdaptiveSpecimenTemplateValidator {
        return AdaptiveSpecimenTemplateValidator(
            rules: [
                AdaptiveSpecimenTemplateAllowedProcedureCodeRule(allowed: ["batched", "primary", "rolling"]),
                AdaptiveSpecimenTemplateProcedureCodeLengthRule(maxLength: 16),
                AdaptiveSpecimenTemplateRevisionRangeRule(min: 120, max: 86400),
                AdaptiveSpecimenTemplateRequiredTitleRule(message: "adaptive specimen template needs this field"),
                AdaptiveSpecimenTemplateRequiredCodeRule(message: "adaptive specimen template needs this field"),
                AdaptiveSpecimenTemplateRequiredProcedureCodeRule(
                    message: "adaptive specimen template needs this field"
                ),
            ]
        )
    }
}
