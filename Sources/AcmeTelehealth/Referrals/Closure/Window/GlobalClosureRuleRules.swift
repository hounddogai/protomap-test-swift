import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global closure rule must pass. Check returns its problems, or none.
    protocol GlobalClosureRuleRule {
        func check(_ item: GlobalClosureRule) -> [String]
    }

    final class GlobalClosureRuleRequiredNameRule: GlobalClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalClosureRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalClosureRuleAllowedDescriptionRule: GlobalClosureRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalClosureRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is unknown"]
            }
            return []
        }
    }

    final class GlobalClosureRuleRequiredCodeRule: GlobalClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalClosureRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalClosureRulePriorityRangeRule: GlobalClosureRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalClosureRule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global closure rule.
    final class GlobalClosureRuleValidator {
        var rules: [any GlobalClosureRuleRule]

        init(rules: [any GlobalClosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalClosureRule) -> [String] {
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

        func requireValid(_ item: GlobalClosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalClosureRule]) -> [String: [String]] {
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

    static func defaultGlobalClosureRuleValidator() -> GlobalClosureRuleValidator {
        return GlobalClosureRuleValidator(
            rules: [
                GlobalClosureRuleRequiredNameRule(message: "global closure rule needs a value"),
                GlobalClosureRuleAllowedDescriptionRule(allowed: ["manual", "pending", "adaptive"]),
                GlobalClosureRuleRequiredCodeRule(message: "global closure rule needs an entry"),
                GlobalClosureRulePriorityRangeRule(min: 80, max: 255),
            ]
        )
    }
}
