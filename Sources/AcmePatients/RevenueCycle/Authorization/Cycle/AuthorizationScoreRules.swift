import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization score must pass. Check returns its problems, or none.
    protocol AuthorizationScoreRule {
        func check(_ item: AuthorizationScore) -> [String]
    }

    final class AuthorizationScoreContactEmailLengthRule: AuthorizationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationScore) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationScoreRequiredTitleRule: AuthorizationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationScoreRequiredCodeRule: AuthorizationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a authorization score.
    final class AuthorizationScoreValidator {
        var rules: [any AuthorizationScoreRule]

        init(rules: [any AuthorizationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationScore) -> [String] {
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

        func requireValid(_ item: AuthorizationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationScore]) -> [String: [String]] {
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

    static func defaultAuthorizationScoreValidator() -> AuthorizationScoreValidator {
        return AuthorizationScoreValidator(
            rules: [
                AuthorizationScoreContactEmailLengthRule(maxLength: 1000),
                AuthorizationScoreRequiredTitleRule(message: "authorization score needs this field"),
                AuthorizationScoreRequiredCodeRule(message: "authorization score needs this field"),
            ]
        )
    }
}
