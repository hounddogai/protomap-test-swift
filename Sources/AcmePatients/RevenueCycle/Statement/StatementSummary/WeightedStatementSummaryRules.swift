import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted statement summary must pass. Check returns its problems, or none.
    protocol WeightedStatementSummaryRule {
        func check(_ item: WeightedStatementSummary) -> [String]
    }

    final class WeightedStatementSummaryRequiredCodeRule: WeightedStatementSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedStatementSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedStatementSummaryAllowedCodeRule: WeightedStatementSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedStatementSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class WeightedStatementSummaryThresholdRangeRule: WeightedStatementSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedStatementSummary) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted statement summary.
    final class WeightedStatementSummaryValidator {
        var rules: [any WeightedStatementSummaryRule]

        init(rules: [any WeightedStatementSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedStatementSummary) -> [String] {
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

        func requireValid(_ item: WeightedStatementSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedStatementSummary]) -> [String: [String]] {
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

    static func defaultWeightedStatementSummaryValidator() -> WeightedStatementSummaryValidator {
        return WeightedStatementSummaryValidator(
            rules: [
                WeightedStatementSummaryRequiredCodeRule(message: "weighted statement summary needs this field"),
                WeightedStatementSummaryAllowedCodeRule(allowed: ["legacy", "pending"]),
                WeightedStatementSummaryThresholdRangeRule(min: 7.9, max: 2713.8),
            ]
        )
    }
}
