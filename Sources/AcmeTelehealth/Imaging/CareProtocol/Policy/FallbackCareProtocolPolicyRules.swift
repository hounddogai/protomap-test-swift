import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback care protocol policy must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolPolicyRule {
        func check(_ item: FallbackCareProtocolPolicy) -> [String]
    }

    final class FallbackCareProtocolPolicyRequiredCodeRule: FallbackCareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolPolicyAllowedPayerRule: FallbackCareProtocolPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCareProtocolPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is missing"]
            }
            return []
        }
    }

    final class FallbackCareProtocolPolicySpecialtyLengthRule: FallbackCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolPolicy) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol policy.
    final class FallbackCareProtocolPolicyValidator {
        var rules: [any FallbackCareProtocolPolicyRule]

        init(rules: [any FallbackCareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolPolicyValidator() -> FallbackCareProtocolPolicyValidator {
        return FallbackCareProtocolPolicyValidator(
            rules: [
                FallbackCareProtocolPolicyRequiredCodeRule(message: "fallback care protocol policy needs an entry"),
                FallbackCareProtocolPolicyAllowedPayerRule(allowed: ["legacy", "strict", "global"]),
                FallbackCareProtocolPolicySpecialtyLengthRule(maxLength: 64),
            ]
        )
    }
}
