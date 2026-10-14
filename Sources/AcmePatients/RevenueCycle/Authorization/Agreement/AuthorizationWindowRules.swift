import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization window must pass. Check returns its problems, or none.
    protocol AuthorizationWindowRule {
        func check(_ item: AuthorizationWindow) -> [String]
    }

    final class AuthorizationWindowNameLengthRule: AuthorizationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationWindowRequiredCountryRule: AuthorizationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationWindow) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationWindowRequiredTitleRule: AuthorizationWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationWindowRetriesRangeRule: AuthorizationWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationWindow) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization window.
    final class AuthorizationWindowValidator {
        var rules: [any AuthorizationWindowRule]

        init(rules: [any AuthorizationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationWindow]) -> [String: [String]] {
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

    static func defaultAuthorizationWindowValidator() -> AuthorizationWindowValidator {
        return AuthorizationWindowValidator(
            rules: [
                AuthorizationWindowNameLengthRule(maxLength: 80),
                AuthorizationWindowRequiredCountryRule(message: "authorization window needs a value"),
                AuthorizationWindowRequiredTitleRule(message: "authorization window needs this field"),
                AuthorizationWindowRetriesRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
