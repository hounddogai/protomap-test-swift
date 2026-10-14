import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary proxy policy must pass. Check returns its problems, or none.
    protocol PrimaryProxyPolicyRule {
        func check(_ item: PrimaryProxyPolicy) -> [String]
    }

    final class PrimaryProxyPolicyAllowedTitleRule: PrimaryProxyPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryProxyPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryProxyPolicyRequiredTitleRule: PrimaryProxyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryProxyPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryProxyPolicyLabelLengthRule: PrimaryProxyPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryProxyPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary proxy policy.
    final class PrimaryProxyPolicyValidator {
        var rules: [any PrimaryProxyPolicyRule]

        init(rules: [any PrimaryProxyPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryProxyPolicy) -> [String] {
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

        func requireValid(_ item: PrimaryProxyPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryProxyPolicy]) -> [String: [String]] {
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

    static func defaultPrimaryProxyPolicyValidator() -> PrimaryProxyPolicyValidator {
        return PrimaryProxyPolicyValidator(
            rules: [
                PrimaryProxyPolicyAllowedTitleRule(allowed: []),
                PrimaryProxyPolicyRequiredTitleRule(message: "primary proxy policy needs this field"),
                PrimaryProxyPolicyLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
