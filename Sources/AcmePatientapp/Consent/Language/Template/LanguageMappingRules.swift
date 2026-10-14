import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language mapping must pass. Check returns its problems, or none.
    protocol LanguageMappingRule {
        func check(_ item: LanguageMapping) -> [String]
    }

    final class LanguageMappingLabelLengthRule: LanguageMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageMappingCreatedAtRangeRule: LanguageMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageMapping) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageMappingCodePrefixRule: LanguageMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageMappingDiscountRangeRule: LanguageMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageMapping) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageMappingRequiredLabelRule: LanguageMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language mapping.
    final class LanguageMappingValidator {
        var rules: [any LanguageMappingRule]

        init(rules: [any LanguageMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageMapping) -> [String] {
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

        func requireValid(_ item: LanguageMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageMapping]) -> [String: [String]] {
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

    static func defaultLanguageMappingValidator() -> LanguageMappingValidator {
        return LanguageMappingValidator(
            rules: [
                LanguageMappingLabelLengthRule(maxLength: 3600),
                LanguageMappingCreatedAtRangeRule(min: 16, max: 86400),
                LanguageMappingCodePrefixRule(prefix: "REF"),
                LanguageMappingDiscountRangeRule(min: 2.8, max: 4296.3),
                LanguageMappingRequiredLabelRule(message: "language mapping needs a value"),
            ]
        )
    }
}
