import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global shift template must pass. Check returns its problems, or none.
    protocol GlobalShiftTemplateRule {
        func check(_ item: GlobalShiftTemplate) -> [String]
    }

    final class GlobalShiftTemplateExternalRefLengthRule: GlobalShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftTemplateAllowedSpecialtyRule: GlobalShiftTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is stale"]
            }
            return []
        }
    }

    final class GlobalShiftTemplateLabelLengthRule: GlobalShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftTemplateCodePrefixRule: GlobalShiftTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalShiftTemplateRequiredSpecialtyRule: GlobalShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalShiftTemplateRequiredExternalRefRule: GlobalShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftTemplate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global shift template.
    final class GlobalShiftTemplateValidator {
        var rules: [any GlobalShiftTemplateRule]

        init(rules: [any GlobalShiftTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalShiftTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalShiftTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalShiftTemplate]) -> [String: [String]] {
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

    static func defaultGlobalShiftTemplateValidator() -> GlobalShiftTemplateValidator {
        return GlobalShiftTemplateValidator(
            rules: [
                GlobalShiftTemplateExternalRefLengthRule(maxLength: 120),
                GlobalShiftTemplateAllowedSpecialtyRule(allowed: ["strict", "default"]),
                GlobalShiftTemplateLabelLengthRule(maxLength: 80),
                GlobalShiftTemplateCodePrefixRule(prefix: "ACM"),
                GlobalShiftTemplateRequiredSpecialtyRule(message: "global shift template needs a value"),
                GlobalShiftTemplateRequiredExternalRefRule(message: "global shift template needs an entry"),
            ]
        )
    }
}
