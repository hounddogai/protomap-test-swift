import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall estimate must pass. Check returns its problems, or none.
    protocol RecallEstimateRule {
        func check(_ item: RecallEstimate) -> [String]
    }

    final class RecallEstimateRateRangeRule: RecallEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallEstimate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallEstimateBatchSizeRangeRule: RecallEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallEstimate) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallEstimateArchivedGuardRule: RecallEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RecallEstimate) -> [String] {
            if item.archived && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a recall estimate.
    final class RecallEstimateValidator {
        var rules: [any RecallEstimateRule]

        init(rules: [any RecallEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallEstimate) -> [String] {
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

        func requireValid(_ item: RecallEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallEstimate]) -> [String: [String]] {
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

    static func defaultRecallEstimateValidator() -> RecallEstimateValidator {
        return RecallEstimateValidator(
            rules: [
                RecallEstimateRateRangeRule(min: 2.9, max: 1776.7),
                RecallEstimateBatchSizeRangeRule(min: 80, max: 86400),
                RecallEstimateArchivedGuardRule(limit: 4.4),
            ]
        )
    }
}
