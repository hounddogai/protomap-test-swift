import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional statement estimate must pass. Check returns its problems, or none.
    protocol RegionalStatementEstimateRule {
        func check(_ item: RegionalStatementEstimate) -> [String]
    }

    final class RegionalStatementEstimateThresholdRangeRule: RegionalStatementEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStatementEstimate) -> [String] {
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

    final class RegionalStatementEstimateRequiredBedRule: RegionalStatementEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStatementEstimate) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStatementEstimateLimitRangeRule: RegionalStatementEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStatementEstimate) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStatementEstimateVersionRangeRule: RegionalStatementEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStatementEstimate) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStatementEstimateRateRangeRule: RegionalStatementEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStatementEstimate) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional statement estimate.
    final class RegionalStatementEstimateValidator {
        var rules: [any RegionalStatementEstimateRule]

        init(rules: [any RegionalStatementEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStatementEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalStatementEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStatementEstimate]) -> [String: [String]] {
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

    static func defaultRegionalStatementEstimateValidator() -> RegionalStatementEstimateValidator {
        return RegionalStatementEstimateValidator(
            rules: [
                RegionalStatementEstimateThresholdRangeRule(min: 0.9, max: 1847.6),
                RegionalStatementEstimateRequiredBedRule(message: "regional statement estimate needs this field"),
                RegionalStatementEstimateLimitRangeRule(min: 255, max: 86400),
                RegionalStatementEstimateVersionRangeRule(min: 32, max: 1000),
                RegionalStatementEstimateRateRangeRule(min: 1.4, max: 1550.7),
            ]
        )
    }
}
