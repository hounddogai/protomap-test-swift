import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization agreement must pass. Check returns its problems, or none.
    protocol AuthorizationAgreementRule {
        func check(_ item: AuthorizationAgreement) -> [String]
    }

    final class AuthorizationAgreementNameLengthRule: AuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAgreementCountryLengthRule: AuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAgreement) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAgreementAllowedCountryRule: AuthorizationAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is out of range"]
            }
            return []
        }
    }

    final class AuthorizationAgreementWindowDaysRangeRule: AuthorizationAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationAgreement) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization agreement.
    final class AuthorizationAgreementValidator {
        var rules: [any AuthorizationAgreementRule]

        init(rules: [any AuthorizationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationAgreement]) -> [String: [String]] {
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

    static func defaultAuthorizationAgreementValidator() -> AuthorizationAgreementValidator {
        return AuthorizationAgreementValidator(
            rules: [
                AuthorizationAgreementNameLengthRule(maxLength: 120),
                AuthorizationAgreementCountryLengthRule(maxLength: 255),
                AuthorizationAgreementAllowedCountryRule(allowed: ["default"]),
                AuthorizationAgreementWindowDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
