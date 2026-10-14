import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling denial rule must pass. Check returns its problems, or none.
    protocol RollingDenialRuleRule {
        func check(_ item: RollingDenialRule) -> [String]
    }

    final class RollingDenialRuleDiscountRangeRule: RollingDenialRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDenialRule) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDenialRuleCreatedAtRangeRule: RollingDenialRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDenialRule) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDenialRuleRequiredCodeRule: RollingDenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDenialRuleStartsAtRangeRule: RollingDenialRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDenialRule) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingDenialRuleRequiredTitleRule: RollingDenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling denial rule.
    final class RollingDenialRuleValidator {
        var rules: [any RollingDenialRuleRule]

        init(rules: [any RollingDenialRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDenialRule) -> [String] {
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

        func requireValid(_ item: RollingDenialRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDenialRule]) -> [String: [String]] {
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

    static func defaultRollingDenialRuleValidator() -> RollingDenialRuleValidator {
        return RollingDenialRuleValidator(
            rules: [
                RollingDenialRuleDiscountRangeRule(min: 8.1, max: 1376.8),
                RollingDenialRuleCreatedAtRangeRule(min: 32, max: 80),
                RollingDenialRuleRequiredCodeRule(message: "rolling denial rule needs an entry"),
                RollingDenialRuleStartsAtRangeRule(min: 16, max: 120),
                RollingDenialRuleRequiredTitleRule(message: "rolling denial rule needs this field"),
            ]
        )
    }
}
