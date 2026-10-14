import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback cleaning template must pass. Check returns its problems, or none.
    protocol FallbackCleaningTemplateRule {
        func check(_ item: FallbackCleaningTemplate) -> [String]
    }

    final class FallbackCleaningTemplateUnitLengthRule: FallbackCleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningTemplateCodeLengthRule: FallbackCleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningTemplateExternalRefLengthRule: FallbackCleaningTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCleaningTemplateRequiredCodeRule: FallbackCleaningTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCleaningTemplateAllowedUnitRule: FallbackCleaningTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is stale"]
            }
            return []
        }
    }

    final class FallbackCleaningTemplateCreatedAtRangeRule: FallbackCleaningTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCleaningTemplate) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback cleaning template.
    final class FallbackCleaningTemplateValidator {
        var rules: [any FallbackCleaningTemplateRule]

        init(rules: [any FallbackCleaningTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCleaningTemplate) -> [String] {
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

        func requireValid(_ item: FallbackCleaningTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCleaningTemplate]) -> [String: [String]] {
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

    static func defaultFallbackCleaningTemplateValidator() -> FallbackCleaningTemplateValidator {
        return FallbackCleaningTemplateValidator(
            rules: [
                FallbackCleaningTemplateUnitLengthRule(maxLength: 80),
                FallbackCleaningTemplateCodeLengthRule(maxLength: 16),
                FallbackCleaningTemplateExternalRefLengthRule(maxLength: 1000),
                FallbackCleaningTemplateRequiredCodeRule(message: "fallback cleaning template needs an entry"),
                FallbackCleaningTemplateAllowedUnitRule(allowed: []),
                FallbackCleaningTemplateCreatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
