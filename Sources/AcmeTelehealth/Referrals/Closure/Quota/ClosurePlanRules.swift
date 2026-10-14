import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure plan must pass. Check returns its problems, or none.
    protocol ClosurePlanRule {
        func check(_ item: ClosurePlan) -> [String]
    }

    final class ClosurePlanAmountRangeRule: ClosurePlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosurePlan) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosurePlanRequiredUnitRule: ClosurePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosurePlan) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosurePlanTagsLimitRule: ClosurePlanRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ClosurePlan) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a closure plan.
    final class ClosurePlanValidator {
        var rules: [any ClosurePlanRule]

        init(rules: [any ClosurePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosurePlan) -> [String] {
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

        func requireValid(_ item: ClosurePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosurePlan]) -> [String: [String]] {
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

    static func defaultClosurePlanValidator() -> ClosurePlanValidator {
        return ClosurePlanValidator(
            rules: [
                ClosurePlanAmountRangeRule(min: 1.8, max: 4347.0),
                ClosurePlanRequiredUnitRule(message: "closure plan needs a value"),
                ClosurePlanTagsLimitRule(maxCount: 16, banned: ["lenient", "regional", "capped"]),
            ]
        )
    }
}
