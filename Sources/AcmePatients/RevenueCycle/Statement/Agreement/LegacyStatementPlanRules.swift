import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy statement plan must pass. Check returns its problems, or none.
    protocol LegacyStatementPlanRule {
        func check(_ item: LegacyStatementPlan) -> [String]
    }

    final class LegacyStatementPlanAttemptsRangeRule: LegacyStatementPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStatementPlan) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyStatementPlanAllowedCodeRule: LegacyStatementPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyStatementPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class LegacyStatementPlanRequiredCodeRule: LegacyStatementPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStatementPlanRequiredLabelRule: LegacyStatementPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStatementPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy statement plan.
    final class LegacyStatementPlanValidator {
        var rules: [any LegacyStatementPlanRule]

        init(rules: [any LegacyStatementPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStatementPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyStatementPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStatementPlan]) -> [String: [String]] {
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

    static func defaultLegacyStatementPlanValidator() -> LegacyStatementPlanValidator {
        return LegacyStatementPlanValidator(
            rules: [
                LegacyStatementPlanAttemptsRangeRule(min: 32, max: 64),
                LegacyStatementPlanAllowedCodeRule(allowed: ["batched", "weighted"]),
                LegacyStatementPlanRequiredCodeRule(message: "legacy statement plan needs this field"),
                LegacyStatementPlanRequiredLabelRule(message: "legacy statement plan needs this field"),
            ]
        )
    }
}
