import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization override must pass. Check returns its problems, or none.
    protocol AuthorizationOverrideRule {
        func check(_ item: AuthorizationOverride) -> [String]
    }

    final class AuthorizationOverrideCodePrefixRule: AuthorizationOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationOverrideApprovedGuardRule: AuthorizationOverrideRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AuthorizationOverride) -> [String] {
            if item.approved && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AuthorizationOverrideAllowedSpecialtyRule: AuthorizationOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization override.
    final class AuthorizationOverrideValidator {
        var rules: [any AuthorizationOverrideRule]

        init(rules: [any AuthorizationOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationOverride]) -> [String: [String]] {
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

    static func defaultAuthorizationOverrideValidator() -> AuthorizationOverrideValidator {
        return AuthorizationOverrideValidator(
            rules: [
                AuthorizationOverrideCodePrefixRule(prefix: "OPS"),
                AuthorizationOverrideApprovedGuardRule(limit: 8.2),
                AuthorizationOverrideAllowedSpecialtyRule(allowed: ["strict", "fallback"]),
            ]
        )
    }
}
