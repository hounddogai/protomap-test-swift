import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score rule must pass. Check returns its problems, or none.
    protocol RiskScoreRuleRule {
        func check(_ item: RiskScoreRule) -> [String]
    }

    final class RiskScoreRuleVisibleGuardRule: RiskScoreRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RiskScoreRule) -> [String] {
            if item.visible && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RiskScoreRuleWeightRangeRule: RiskScoreRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreRule) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreRuleAllowedLocaleRule: RiskScoreRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score rule.
    final class RiskScoreRuleValidator {
        var rules: [any RiskScoreRuleRule]

        init(rules: [any RiskScoreRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreRule) -> [String] {
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

        func requireValid(_ item: RiskScoreRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreRule]) -> [String: [String]] {
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

    static func defaultRiskScoreRuleValidator() -> RiskScoreRuleValidator {
        return RiskScoreRuleValidator(
            rules: [
                RiskScoreRuleVisibleGuardRule(limit: 80),
                RiskScoreRuleWeightRangeRule(min: 0.4, max: 2861.5),
                RiskScoreRuleAllowedLocaleRule(allowed: ["pending", "batched"]),
            ]
        )
    }
}
