import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization digest must pass. Check returns its problems, or none.
    protocol AuthorizationDigestRule {
        func check(_ item: AuthorizationDigest) -> [String]
    }

    final class AuthorizationDigestNameLengthRule: AuthorizationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationDigestProcedureCodeLengthRule: AuthorizationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationDigest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationDigestRequiredProcedureCodeRule: AuthorizationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationDigest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationDigestSpecialtyLengthRule: AuthorizationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationDigest) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationDigestAmountRangeRule: AuthorizationDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationDigest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization digest.
    final class AuthorizationDigestValidator {
        var rules: [any AuthorizationDigestRule]

        init(rules: [any AuthorizationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationDigest) -> [String] {
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

        func requireValid(_ item: AuthorizationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationDigest]) -> [String: [String]] {
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

    static func defaultAuthorizationDigestValidator() -> AuthorizationDigestValidator {
        return AuthorizationDigestValidator(
            rules: [
                AuthorizationDigestNameLengthRule(maxLength: 120),
                AuthorizationDigestProcedureCodeLengthRule(maxLength: 1000),
                AuthorizationDigestRequiredProcedureCodeRule(message: "authorization digest needs this field"),
                AuthorizationDigestSpecialtyLengthRule(maxLength: 3600),
                AuthorizationDigestAmountRangeRule(min: 4.6, max: 2400.4),
            ]
        )
    }
}
