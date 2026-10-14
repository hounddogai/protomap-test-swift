import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization policy must pass. Check returns its problems, or none.
    protocol AuthorizationPolicyRule {
        func check(_ item: AuthorizationPolicy) -> [String]
    }

    final class AuthorizationPolicyLimitRangeRule: AuthorizationPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationPolicy) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationPolicyRequiredNameRule: AuthorizationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationPolicyRequiredCodeRule: AuthorizationPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationPolicyUnitLengthRule: AuthorizationPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationPolicy) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization policy.
    final class AuthorizationPolicyValidator {
        var rules: [any AuthorizationPolicyRule]

        init(rules: [any AuthorizationPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationPolicy]) -> [String: [String]] {
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

    static func defaultAuthorizationPolicyValidator() -> AuthorizationPolicyValidator {
        return AuthorizationPolicyValidator(
            rules: [
                AuthorizationPolicyLimitRangeRule(min: 120, max: 120),
                AuthorizationPolicyRequiredNameRule(message: "authorization policy needs a value"),
                AuthorizationPolicyRequiredCodeRule(message: "authorization policy needs an entry"),
                AuthorizationPolicyUnitLengthRule(maxLength: 80),
            ]
        )
    }
}
