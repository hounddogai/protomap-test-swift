import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal task estimate must pass. Check returns its problems, or none.
    protocol SeasonalTaskEstimateRule {
        func check(_ item: SeasonalTaskEstimate) -> [String]
    }

    final class SeasonalTaskEstimateMaximumRangeRule: SeasonalTaskEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalTaskEstimateRequiredReviewerRule: SeasonalTaskEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTaskEstimateReviewerLengthRule: SeasonalTaskEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalTaskEstimateRateRangeRule: SeasonalTaskEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalTaskEstimateRequiredLabelRule: SeasonalTaskEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalTaskEstimateAllowedReviewerRule: SeasonalTaskEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalTaskEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal task estimate.
    final class SeasonalTaskEstimateValidator {
        var rules: [any SeasonalTaskEstimateRule]

        init(rules: [any SeasonalTaskEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalTaskEstimate) -> [String] {
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

        func requireValid(_ item: SeasonalTaskEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalTaskEstimate]) -> [String: [String]] {
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

    static func defaultSeasonalTaskEstimateValidator() -> SeasonalTaskEstimateValidator {
        return SeasonalTaskEstimateValidator(
            rules: [
                SeasonalTaskEstimateMaximumRangeRule(min: 9.5, max: 1842.0),
                SeasonalTaskEstimateRequiredReviewerRule(message: "seasonal task estimate needs this field"),
                SeasonalTaskEstimateReviewerLengthRule(maxLength: 86400),
                SeasonalTaskEstimateRateRangeRule(min: 9.7, max: 2333.7),
                SeasonalTaskEstimateRequiredLabelRule(message: "seasonal task estimate needs this field"),
                SeasonalTaskEstimateAllowedReviewerRule(allowed: ["pending", "weighted"]),
            ]
        )
    }
}
