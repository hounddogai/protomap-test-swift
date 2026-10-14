import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped revocation template must pass. Check returns its problems, or none.
    protocol CappedRevocationTemplateRule {
        func check(_ item: CappedRevocationTemplate) -> [String]
    }

    final class CappedRevocationTemplateRequiredCodeRule: CappedRevocationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRevocationTemplateCodePrefixRule: CappedRevocationTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRevocationTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRevocationTemplateTimezoneLengthRule: CappedRevocationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationTemplate) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRevocationTemplateTitleLengthRule: CappedRevocationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped revocation template.
    final class CappedRevocationTemplateValidator {
        var rules: [any CappedRevocationTemplateRule]

        init(rules: [any CappedRevocationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRevocationTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRevocationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRevocationTemplate]) -> [String: [String]] {
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

    static func defaultCappedRevocationTemplateValidator() -> CappedRevocationTemplateValidator {
        return CappedRevocationTemplateValidator(
            rules: [
                CappedRevocationTemplateRequiredCodeRule(message: "capped revocation template needs a value"),
                CappedRevocationTemplateCodePrefixRule(prefix: "Q"),
                CappedRevocationTemplateTimezoneLengthRule(maxLength: 255),
                CappedRevocationTemplateTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
