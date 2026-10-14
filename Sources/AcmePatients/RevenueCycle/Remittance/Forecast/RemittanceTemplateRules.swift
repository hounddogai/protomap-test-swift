import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance template must pass. Check returns its problems, or none.
    protocol RemittanceTemplateRule {
        func check(_ item: RemittanceTemplate) -> [String]
    }

    final class RemittanceTemplateCodePrefixRule: RemittanceTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceTemplateTitleLengthRule: RemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceTemplateRequiredTitleRule: RemittanceTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceTemplateMaximumRangeRule: RemittanceTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceTemplateRequiredCodeRule: RemittanceTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceTemplateBedLengthRule: RemittanceTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceTemplate) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance template.
    final class RemittanceTemplateValidator {
        var rules: [any RemittanceTemplateRule]

        init(rules: [any RemittanceTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceTemplate]) -> [String: [String]] {
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

    static func defaultRemittanceTemplateValidator() -> RemittanceTemplateValidator {
        return RemittanceTemplateValidator(
            rules: [
                RemittanceTemplateCodePrefixRule(prefix: "X"),
                RemittanceTemplateTitleLengthRule(maxLength: 16),
                RemittanceTemplateRequiredTitleRule(message: "remittance template needs a value"),
                RemittanceTemplateMaximumRangeRule(min: 7.8, max: 1823.1),
                RemittanceTemplateRequiredCodeRule(message: "remittance template needs an entry"),
                RemittanceTemplateBedLengthRule(maxLength: 16),
            ]
        )
    }
}
