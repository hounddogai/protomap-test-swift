import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization milestone must pass. Check returns its problems, or none.
    protocol AuthorizationMilestoneRule {
        func check(_ item: AuthorizationMilestone) -> [String]
    }

    final class AuthorizationMilestoneRetriesRangeRule: AuthorizationMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationMilestone) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationMilestoneCodePrefixRule: AuthorizationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationMilestoneAllowedTitleRule: AuthorizationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class AuthorizationMilestoneCodeLengthRule: AuthorizationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization milestone.
    final class AuthorizationMilestoneValidator {
        var rules: [any AuthorizationMilestoneRule]

        init(rules: [any AuthorizationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationMilestone) -> [String] {
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

        func requireValid(_ item: AuthorizationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationMilestone]) -> [String: [String]] {
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

    static func defaultAuthorizationMilestoneValidator() -> AuthorizationMilestoneValidator {
        return AuthorizationMilestoneValidator(
            rules: [
                AuthorizationMilestoneRetriesRangeRule(min: 80, max: 1000),
                AuthorizationMilestoneCodePrefixRule(prefix: "ACM"),
                AuthorizationMilestoneAllowedTitleRule(allowed: ["lenient", "regional", "lenient"]),
                AuthorizationMilestoneCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
