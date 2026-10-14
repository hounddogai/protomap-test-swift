import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization claim must pass. Check returns its problems, or none.
    protocol AuthorizationClaimRule {
        func check(_ item: AuthorizationClaim) -> [String]
    }

    final class AuthorizationClaimUnitLengthRule: AuthorizationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationClaim) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationClaimUpdatedAtRangeRule: AuthorizationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationClaim) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationClaimRequiredCodeRule: AuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationClaimRequiredUnitRule: AuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationClaim) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a authorization claim.
    final class AuthorizationClaimValidator {
        var rules: [any AuthorizationClaimRule]

        init(rules: [any AuthorizationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationClaim]) -> [String: [String]] {
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

    static func defaultAuthorizationClaimValidator() -> AuthorizationClaimValidator {
        return AuthorizationClaimValidator(
            rules: [
                AuthorizationClaimUnitLengthRule(maxLength: 86400),
                AuthorizationClaimUpdatedAtRangeRule(min: 32, max: 64),
                AuthorizationClaimRequiredCodeRule(message: "authorization claim needs an entry"),
                AuthorizationClaimRequiredUnitRule(message: "authorization claim needs a value"),
            ]
        )
    }
}
