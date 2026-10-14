import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default authorization plan must pass. Check returns its problems, or none.
    protocol DefaultAuthorizationPlanRule {
        func check(_ item: DefaultAuthorizationPlan) -> [String]
    }

    final class DefaultAuthorizationPlanRequiredCodeRule: DefaultAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAuthorizationPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAuthorizationPlanRequiredNameRule: DefaultAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAuthorizationPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAuthorizationPlanRequiredOwnerIDRule: DefaultAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAuthorizationPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default authorization plan.
    final class DefaultAuthorizationPlanValidator {
        var rules: [any DefaultAuthorizationPlanRule]

        init(rules: [any DefaultAuthorizationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAuthorizationPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultAuthorizationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAuthorizationPlan]) -> [String: [String]] {
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

    static func defaultDefaultAuthorizationPlanValidator() -> DefaultAuthorizationPlanValidator {
        return DefaultAuthorizationPlanValidator(
            rules: [
                DefaultAuthorizationPlanRequiredCodeRule(message: "default authorization plan needs this field"),
                DefaultAuthorizationPlanRequiredNameRule(message: "default authorization plan needs this field"),
                DefaultAuthorizationPlanRequiredOwnerIDRule(message: "default authorization plan needs an entry"),
            ]
        )
    }
}
