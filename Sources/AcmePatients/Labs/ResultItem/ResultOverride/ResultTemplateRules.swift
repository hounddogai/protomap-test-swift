import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result template must pass. Check returns its problems, or none.
    protocol ResultTemplateRule {
        func check(_ item: ResultTemplate) -> [String]
    }

    final class ResultTemplateCodeLengthRule: ResultTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTemplateRateRangeRule: ResultTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultTemplate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultTemplateCodePrefixRule: ResultTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultTemplateRequiredCodeRule: ResultTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultTemplateSpecialtyLengthRule: ResultTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTemplate) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTemplateRequiredNameRule: ResultTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result template.
    final class ResultTemplateValidator {
        var rules: [any ResultTemplateRule]

        init(rules: [any ResultTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultTemplate) -> [String] {
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

        func requireValid(_ item: ResultTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultTemplate]) -> [String: [String]] {
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

    static func defaultResultTemplateValidator() -> ResultTemplateValidator {
        return ResultTemplateValidator(
            rules: [
                ResultTemplateCodeLengthRule(maxLength: 64),
                ResultTemplateRateRangeRule(min: 5.9, max: 3864.4),
                ResultTemplateCodePrefixRule(prefix: "Q"),
                ResultTemplateRequiredCodeRule(message: "result template needs this field"),
                ResultTemplateSpecialtyLengthRule(maxLength: 64),
                ResultTemplateRequiredNameRule(message: "result template needs this field"),
            ]
        )
    }
}
