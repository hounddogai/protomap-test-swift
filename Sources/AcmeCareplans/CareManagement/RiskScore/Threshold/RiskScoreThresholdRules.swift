import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score threshold must pass. Check returns its problems, or none.
    protocol RiskScoreThresholdRule {
        func check(_ item: RiskScoreThreshold) -> [String]
    }

    final class RiskScoreThresholdArchivedGuardRule: RiskScoreThresholdRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RiskScoreThreshold) -> [String] {
            if item.archived && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RiskScoreThresholdBudgetRangeRule: RiskScoreThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreThreshold) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreThresholdMarginRangeRule: RiskScoreThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreThreshold) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a risk score threshold.
    final class RiskScoreThresholdValidator {
        var rules: [any RiskScoreThresholdRule]

        init(rules: [any RiskScoreThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreThreshold]) -> [String: [String]] {
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

    static func defaultRiskScoreThresholdValidator() -> RiskScoreThresholdValidator {
        return RiskScoreThresholdValidator(
            rules: [
                RiskScoreThresholdArchivedGuardRule(limit: 7.6),
                RiskScoreThresholdBudgetRangeRule(min: 8.3, max: 4408.0),
                RiskScoreThresholdMarginRangeRule(min: 5.2, max: 3851.9),
            ]
        )
    }
}
