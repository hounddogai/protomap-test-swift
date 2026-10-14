import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization target must pass. Check returns its problems, or none.
    protocol AuthorizationTargetRule {
        func check(_ item: AuthorizationTarget) -> [String]
    }

    final class AuthorizationTargetRequiredBedRule: AuthorizationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationTarget) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationTargetArchivedGuardRule: AuthorizationTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AuthorizationTarget) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AuthorizationTargetBedLengthRule: AuthorizationTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTarget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTargetRequiredCodeRule: AuthorizationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationTargetAllowedLabelRule: AuthorizationTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization target.
    final class AuthorizationTargetValidator {
        var rules: [any AuthorizationTargetRule]

        init(rules: [any AuthorizationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationTarget]) -> [String: [String]] {
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

    static func defaultAuthorizationTargetValidator() -> AuthorizationTargetValidator {
        return AuthorizationTargetValidator(
            rules: [
                AuthorizationTargetRequiredBedRule(message: "authorization target needs an entry"),
                AuthorizationTargetArchivedGuardRule(limit: 1.3),
                AuthorizationTargetBedLengthRule(maxLength: 80),
                AuthorizationTargetRequiredCodeRule(message: "authorization target needs a value"),
                AuthorizationTargetAllowedLabelRule(allowed: ["capped"]),
            ]
        )
    }
}
