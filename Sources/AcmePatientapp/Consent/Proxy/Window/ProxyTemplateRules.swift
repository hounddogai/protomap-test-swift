import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy template must pass. Check returns its problems, or none.
    protocol ProxyTemplateRule {
        func check(_ item: ProxyTemplate) -> [String]
    }

    final class ProxyTemplateCodePrefixRule: ProxyTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyTemplateTitleLengthRule: ProxyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyTemplateRequiredDiagnosisCodeRule: ProxyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTemplate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTemplateCodeLengthRule: ProxyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyTemplateVersionRangeRule: ProxyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyTemplate) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy template.
    final class ProxyTemplateValidator {
        var rules: [any ProxyTemplateRule]

        init(rules: [any ProxyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyTemplate]) -> [String: [String]] {
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

    static func defaultProxyTemplateValidator() -> ProxyTemplateValidator {
        return ProxyTemplateValidator(
            rules: [
                ProxyTemplateCodePrefixRule(prefix: "ACM"),
                ProxyTemplateTitleLengthRule(maxLength: 255),
                ProxyTemplateRequiredDiagnosisCodeRule(message: "proxy template needs an entry"),
                ProxyTemplateCodeLengthRule(maxLength: 120),
                ProxyTemplateVersionRangeRule(min: 16, max: 64),
            ]
        )
    }
}
