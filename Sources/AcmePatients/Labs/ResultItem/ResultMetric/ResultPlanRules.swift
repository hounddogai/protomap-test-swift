import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result plan must pass. Check returns its problems, or none.
    protocol ResultPlanRule {
        func check(_ item: ResultPlan) -> [String]
    }

    final class ResultPlanRequiredNameRule: ResultPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultPlanGraceDaysRangeRule: ResultPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultPlan) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultPlanAllowedNameRule: ResultPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a result plan.
    final class ResultPlanValidator {
        var rules: [any ResultPlanRule]

        init(rules: [any ResultPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultPlan]) -> [String: [String]] {
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

    static func defaultResultPlanValidator() -> ResultPlanValidator {
        return ResultPlanValidator(
            rules: [
                ResultPlanRequiredNameRule(message: "result plan needs an entry"),
                ResultPlanGraceDaysRangeRule(min: 255, max: 86400),
                ResultPlanAllowedNameRule(allowed: ["tiered"]),
            ]
        )
    }
}
