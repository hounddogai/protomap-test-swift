import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score rollup must pass. Check returns its problems, or none.
    protocol RiskScoreRollupRule {
        func check(_ item: RiskScoreRollup) -> [String]
    }

    final class RiskScoreRollupWeightRangeRule: RiskScoreRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreRollup) -> [String] {
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

    final class RiskScoreRollupCurrencyLengthRule: RiskScoreRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreRollup) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreRollupAmountRangeRule: RiskScoreRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreRollup) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a risk score rollup.
    final class RiskScoreRollupValidator {
        var rules: [any RiskScoreRollupRule]

        init(rules: [any RiskScoreRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreRollup]) -> [String: [String]] {
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

    static func defaultRiskScoreRollupValidator() -> RiskScoreRollupValidator {
        return RiskScoreRollupValidator(
            rules: [
                RiskScoreRollupWeightRangeRule(min: 0.2, max: 2654.6),
                RiskScoreRollupCurrencyLengthRule(maxLength: 86400),
                RiskScoreRollupAmountRangeRule(min: 1.5, max: 2192.2),
            ]
        )
    }
}
