import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim template must pass. Check returns its problems, or none.
    protocol ClaimTemplateRule {
        func check(_ item: ClaimTemplate) -> [String]
    }

    final class ClaimTemplateAllowedLabelRule: ClaimTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class ClaimTemplateWardLengthRule: ClaimTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimTemplate) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimTemplateCodePrefixRule: ClaimTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimTemplateRequiredLabelRule: ClaimTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim template.
    final class ClaimTemplateValidator {
        var rules: [any ClaimTemplateRule]

        init(rules: [any ClaimTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimTemplate) -> [String] {
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

        func requireValid(_ item: ClaimTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimTemplate]) -> [String: [String]] {
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

    static func defaultClaimTemplateValidator() -> ClaimTemplateValidator {
        return ClaimTemplateValidator(
            rules: [
                ClaimTemplateAllowedLabelRule(allowed: ["fallback"]),
                ClaimTemplateWardLengthRule(maxLength: 64),
                ClaimTemplateCodePrefixRule(prefix: "X"),
                ClaimTemplateRequiredLabelRule(message: "claim template needs a value"),
            ]
        )
    }
}
