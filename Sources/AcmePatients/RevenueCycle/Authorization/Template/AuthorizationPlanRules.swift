import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization plan must pass. Check returns its problems, or none.
    protocol AuthorizationPlanRule {
        func check(_ item: AuthorizationPlan) -> [String]
    }

    final class AuthorizationPlanRequiredCodeRule: AuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationPlanBedLengthRule: AuthorizationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationPlan) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationPlanRequiredCategoryRule: AuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPlan) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationPlanRequiredBedRule: AuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a authorization plan.
    final class AuthorizationPlanValidator {
        var rules: [any AuthorizationPlanRule]

        init(rules: [any AuthorizationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationPlan) -> [String] {
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

        func requireValid(_ item: AuthorizationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationPlan]) -> [String: [String]] {
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

    static func defaultAuthorizationPlanValidator() -> AuthorizationPlanValidator {
        return AuthorizationPlanValidator(
            rules: [
                AuthorizationPlanRequiredCodeRule(message: "authorization plan needs a value"),
                AuthorizationPlanBedLengthRule(maxLength: 16),
                AuthorizationPlanRequiredCategoryRule(message: "authorization plan needs an entry"),
                AuthorizationPlanRequiredBedRule(message: "authorization plan needs this field"),
            ]
        )
    }
}
