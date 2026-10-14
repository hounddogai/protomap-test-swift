import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim template must pass. Check returns its problems, or none.
    protocol AdaptiveClaimTemplateRule {
        func check(_ item: AdaptiveClaimTemplate) -> [String]
    }

    final class AdaptiveClaimTemplateAllowedNameRule: AdaptiveClaimTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveClaimTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveClaimTemplateCodePrefixRule: AdaptiveClaimTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveClaimTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveClaimTemplateContactEmailLengthRule: AdaptiveClaimTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimTemplate) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim template.
    final class AdaptiveClaimTemplateValidator {
        var rules: [any AdaptiveClaimTemplateRule]

        init(rules: [any AdaptiveClaimTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveClaimTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimTemplateValidator() -> AdaptiveClaimTemplateValidator {
        return AdaptiveClaimTemplateValidator(
            rules: [
                AdaptiveClaimTemplateAllowedNameRule(allowed: ["lenient"]),
                AdaptiveClaimTemplateCodePrefixRule(prefix: "ACM"),
                AdaptiveClaimTemplateContactEmailLengthRule(maxLength: 80),
            ]
        )
    }
}
