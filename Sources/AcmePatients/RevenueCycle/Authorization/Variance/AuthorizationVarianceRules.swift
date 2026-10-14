import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization variance must pass. Check returns its problems, or none.
    protocol AuthorizationVarianceRule {
        func check(_ item: AuthorizationVariance) -> [String]
    }

    final class AuthorizationVarianceAllowedExternalRefRule: AuthorizationVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is too long"]
            }
            return []
        }
    }

    final class AuthorizationVarianceCodePrefixRule: AuthorizationVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationVarianceCodeLengthRule: AuthorizationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationVarianceExternalRefLengthRule: AuthorizationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization variance.
    final class AuthorizationVarianceValidator {
        var rules: [any AuthorizationVarianceRule]

        init(rules: [any AuthorizationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationVariance) -> [String] {
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

        func requireValid(_ item: AuthorizationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationVariance]) -> [String: [String]] {
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

    static func defaultAuthorizationVarianceValidator() -> AuthorizationVarianceValidator {
        return AuthorizationVarianceValidator(
            rules: [
                AuthorizationVarianceAllowedExternalRefRule(allowed: []),
                AuthorizationVarianceCodePrefixRule(prefix: "X"),
                AuthorizationVarianceCodeLengthRule(maxLength: 64),
                AuthorizationVarianceExternalRefLengthRule(maxLength: 16),
            ]
        )
    }
}
