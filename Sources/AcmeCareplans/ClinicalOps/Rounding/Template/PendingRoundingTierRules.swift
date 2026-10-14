import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending rounding tier must pass. Check returns its problems, or none.
    protocol PendingRoundingTierRule {
        func check(_ item: PendingRoundingTier) -> [String]
    }

    final class PendingRoundingTierThresholdRangeRule: PendingRoundingTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRoundingTier) -> [String] {
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

    final class PendingRoundingTierRetriesRangeRule: PendingRoundingTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRoundingTier) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRoundingTierRequiredCodeRule: PendingRoundingTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRoundingTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRoundingTierGraceDaysRangeRule: PendingRoundingTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRoundingTier) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending rounding tier.
    final class PendingRoundingTierValidator {
        var rules: [any PendingRoundingTierRule]

        init(rules: [any PendingRoundingTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRoundingTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRoundingTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRoundingTier]) -> [String: [String]] {
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

    static func defaultPendingRoundingTierValidator() -> PendingRoundingTierValidator {
        return PendingRoundingTierValidator(
            rules: [
                PendingRoundingTierThresholdRangeRule(min: 1.7, max: 3851.5),
                PendingRoundingTierRetriesRangeRule(min: 32, max: 3600),
                PendingRoundingTierRequiredCodeRule(message: "pending rounding tier needs a value"),
                PendingRoundingTierGraceDaysRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
