import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched rounding metric must pass. Check returns its problems, or none.
    protocol BatchedRoundingMetricRule {
        func check(_ item: BatchedRoundingMetric) -> [String]
    }

    final class BatchedRoundingMetricCodeLengthRule: BatchedRoundingMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRoundingMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRoundingMetricCurrencyLengthRule: BatchedRoundingMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRoundingMetric) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRoundingMetricArchivedGuardRule: BatchedRoundingMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedRoundingMetric) -> [String] {
            if item.archived && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a batched rounding metric.
    final class BatchedRoundingMetricValidator {
        var rules: [any BatchedRoundingMetricRule]

        init(rules: [any BatchedRoundingMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRoundingMetric) -> [String] {
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

        func requireValid(_ item: BatchedRoundingMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRoundingMetric]) -> [String: [String]] {
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

    static func defaultBatchedRoundingMetricValidator() -> BatchedRoundingMetricValidator {
        return BatchedRoundingMetricValidator(
            rules: [
                BatchedRoundingMetricCodeLengthRule(maxLength: 3600),
                BatchedRoundingMetricCurrencyLengthRule(maxLength: 64),
                BatchedRoundingMetricArchivedGuardRule(limit: 64),
            ]
        )
    }
}
