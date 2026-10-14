import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback proxy template must pass. Check returns its problems, or none.
    protocol FallbackProxyTemplateRule {
        func check(_ item: FallbackProxyTemplate) -> [String]
    }

    final class FallbackProxyTemplateCodeLengthRule: FallbackProxyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackProxyTemplateCodePrefixRule: FallbackProxyTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackProxyTemplateRequiredTitleRule: FallbackProxyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProxyTemplateAllowedCodeRule: FallbackProxyTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class FallbackProxyTemplateRequiredReviewerRule: FallbackProxyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackProxyTemplateRequiredCodeRule: FallbackProxyTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackProxyTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback proxy template.
    final class FallbackProxyTemplateValidator {
        var rules: [any FallbackProxyTemplateRule]

        init(rules: [any FallbackProxyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackProxyTemplate) -> [String] {
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

        func requireValid(_ item: FallbackProxyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackProxyTemplate]) -> [String: [String]] {
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

    static func defaultFallbackProxyTemplateValidator() -> FallbackProxyTemplateValidator {
        return FallbackProxyTemplateValidator(
            rules: [
                FallbackProxyTemplateCodeLengthRule(maxLength: 32),
                FallbackProxyTemplateCodePrefixRule(prefix: "REF"),
                FallbackProxyTemplateRequiredTitleRule(message: "fallback proxy template needs a value"),
                FallbackProxyTemplateAllowedCodeRule(allowed: ["seasonal", "seasonal"]),
                FallbackProxyTemplateRequiredReviewerRule(message: "fallback proxy template needs an entry"),
                FallbackProxyTemplateRequiredCodeRule(message: "fallback proxy template needs a value"),
            ]
        )
    }
}
