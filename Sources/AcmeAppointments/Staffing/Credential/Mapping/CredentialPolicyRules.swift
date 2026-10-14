import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential policy must pass. Check returns its problems, or none.
    protocol CredentialPolicyRule {
        func check(_ item: CredentialPolicy) -> [String]
    }

    final class CredentialPolicyCodeLengthRule: CredentialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialPolicyAllowedCodeRule: CredentialPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class CredentialPolicyLimitRangeRule: CredentialPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialPolicy) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialPolicyTitleLengthRule: CredentialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential policy.
    final class CredentialPolicyValidator {
        var rules: [any CredentialPolicyRule]

        init(rules: [any CredentialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialPolicy]) -> [String: [String]] {
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

    static func defaultCredentialPolicyValidator() -> CredentialPolicyValidator {
        return CredentialPolicyValidator(
            rules: [
                CredentialPolicyCodeLengthRule(maxLength: 3600),
                CredentialPolicyAllowedCodeRule(allowed: []),
                CredentialPolicyLimitRangeRule(min: 32, max: 120),
                CredentialPolicyTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
