import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement rule must pass. Check returns its problems, or none.
    protocol StatementRuleRule {
        func check(_ item: StatementRule) -> [String]
    }

    final class StatementRulePinnedGuardRule: StatementRuleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StatementRule) -> [String] {
            if item.pinned && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StatementRuleRequiredCodeRule: StatementRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementRuleRequiredRegionRule: StatementRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRule) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement rule.
    final class StatementRuleValidator {
        var rules: [any StatementRuleRule]

        init(rules: [any StatementRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementRule]) -> [String: [String]] {
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

    static func defaultStatementRuleValidator() -> StatementRuleValidator {
        return StatementRuleValidator(
            rules: [
                StatementRulePinnedGuardRule(limit: 9.2),
                StatementRuleRequiredCodeRule(message: "statement rule needs this field"),
                StatementRuleRequiredRegionRule(message: "statement rule needs a value"),
            ]
        )
    }
}
