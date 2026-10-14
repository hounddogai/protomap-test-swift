import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization tier must pass. Check returns its problems, or none.
    protocol AuthorizationTierRule {
        func check(_ item: AuthorizationTier) -> [String]
    }

    final class AuthorizationTierRequiredUnitRule: AuthorizationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationTier) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationTierRequiredCodeRule: AuthorizationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationTierLabelLengthRule: AuthorizationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTierTitleLengthRule: AuthorizationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTierCapacityRangeRule: AuthorizationTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationTier) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization tier.
    final class AuthorizationTierValidator {
        var rules: [any AuthorizationTierRule]

        init(rules: [any AuthorizationTierRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationTier]) -> [String: [String]] {
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

    static func defaultAuthorizationTierValidator() -> AuthorizationTierValidator {
        return AuthorizationTierValidator(
            rules: [
                AuthorizationTierRequiredUnitRule(message: "authorization tier needs a value"),
                AuthorizationTierRequiredCodeRule(message: "authorization tier needs an entry"),
                AuthorizationTierLabelLengthRule(maxLength: 255),
                AuthorizationTierTitleLengthRule(maxLength: 16),
                AuthorizationTierCapacityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
