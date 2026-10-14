import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling follow up rule must pass. Check returns its problems, or none.
    protocol RollingFollowUpRuleRule {
        func check(_ item: RollingFollowUpRule) -> [String]
    }

    final class RollingFollowUpRuleCodePrefixRule: RollingFollowUpRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingFollowUpRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingFollowUpRuleActiveGuardRule: RollingFollowUpRuleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingFollowUpRule) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RollingFollowUpRuleAllowedNameRule: RollingFollowUpRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingFollowUpRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class RollingFollowUpRuleRequiredCodeRule: RollingFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingFollowUpRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling follow up rule.
    final class RollingFollowUpRuleValidator {
        var rules: [any RollingFollowUpRuleRule]

        init(rules: [any RollingFollowUpRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFollowUpRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingFollowUpRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFollowUpRule]) -> [String: [String]] {
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

    static func defaultRollingFollowUpRuleValidator() -> RollingFollowUpRuleValidator {
        return RollingFollowUpRuleValidator(
            rules: [
                RollingFollowUpRuleCodePrefixRule(prefix: "REF"),
                RollingFollowUpRuleActiveGuardRule(limit: 3.5),
                RollingFollowUpRuleAllowedNameRule(allowed: ["default", "rolling", "weighted"]),
                RollingFollowUpRuleRequiredCodeRule(message: "rolling follow up rule needs an entry"),
            ]
        )
    }
}
