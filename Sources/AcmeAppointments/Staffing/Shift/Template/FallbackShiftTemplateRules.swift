import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback shift template must pass. Check returns its problems, or none.
    protocol FallbackShiftTemplateRule {
        func check(_ item: FallbackShiftTemplate) -> [String]
    }

    final class FallbackShiftTemplateAllowedNameRule: FallbackShiftTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class FallbackShiftTemplateLabelLengthRule: FallbackShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackShiftTemplateRequiredNameRule: FallbackShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackShiftTemplateCodePrefixRule: FallbackShiftTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackShiftTemplateRequiredCodeRule: FallbackShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackShiftTemplateCeilingRangeRule: FallbackShiftTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackShiftTemplate) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback shift template.
    final class FallbackShiftTemplateValidator {
        var rules: [any FallbackShiftTemplateRule]

        init(rules: [any FallbackShiftTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackShiftTemplate) -> [String] {
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

        func requireValid(_ item: FallbackShiftTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackShiftTemplate]) -> [String: [String]] {
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

    static func defaultFallbackShiftTemplateValidator() -> FallbackShiftTemplateValidator {
        return FallbackShiftTemplateValidator(
            rules: [
                FallbackShiftTemplateAllowedNameRule(allowed: []),
                FallbackShiftTemplateLabelLengthRule(maxLength: 1000),
                FallbackShiftTemplateRequiredNameRule(message: "fallback shift template needs an entry"),
                FallbackShiftTemplateCodePrefixRule(prefix: "ACM"),
                FallbackShiftTemplateRequiredCodeRule(message: "fallback shift template needs a value"),
                FallbackShiftTemplateCeilingRangeRule(min: 6.2, max: 4461.0),
            ]
        )
    }
}
