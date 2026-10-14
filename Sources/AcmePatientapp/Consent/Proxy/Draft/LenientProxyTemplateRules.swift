import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy template must pass. Check returns its problems, or none.
    protocol LenientProxyTemplateRule {
        func check(_ item: LenientProxyTemplate) -> [String]
    }

    final class LenientProxyTemplateRequiredCountryRule: LenientProxyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyTemplate) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyTemplateRefillsRangeRule: LenientProxyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyTemplate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProxyTemplateNameLengthRule: LenientProxyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProxyTemplateCodeLengthRule: LenientProxyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy template.
    final class LenientProxyTemplateValidator {
        var rules: [any LenientProxyTemplateRule]

        init(rules: [any LenientProxyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProxyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyTemplate]) -> [String: [String]] {
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

    static func defaultLenientProxyTemplateValidator() -> LenientProxyTemplateValidator {
        return LenientProxyTemplateValidator(
            rules: [
                LenientProxyTemplateRequiredCountryRule(message: "lenient proxy template needs a value"),
                LenientProxyTemplateRefillsRangeRule(min: 80, max: 120),
                LenientProxyTemplateNameLengthRule(maxLength: 80),
                LenientProxyTemplateCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
