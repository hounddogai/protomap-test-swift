import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach plan must pass. Check returns its problems, or none.
    protocol TieredOutreachPlanRule {
        func check(_ item: TieredOutreachPlan) -> [String]
    }

    final class TieredOutreachPlanCodePrefixRule: TieredOutreachPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredOutreachPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredOutreachPlanRequiredCodeRule: TieredOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOutreachPlanAllowedCodeRule: TieredOutreachPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOutreachPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered outreach plan.
    final class TieredOutreachPlanValidator {
        var rules: [any TieredOutreachPlanRule]

        init(rules: [any TieredOutreachPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredOutreachPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachPlan]) -> [String: [String]] {
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

    static func defaultTieredOutreachPlanValidator() -> TieredOutreachPlanValidator {
        return TieredOutreachPlanValidator(
            rules: [
                TieredOutreachPlanCodePrefixRule(prefix: "ACM"),
                TieredOutreachPlanRequiredCodeRule(message: "tiered outreach plan needs this field"),
                TieredOutreachPlanAllowedCodeRule(allowed: ["batched", "global"]),
            ]
        )
    }
}
