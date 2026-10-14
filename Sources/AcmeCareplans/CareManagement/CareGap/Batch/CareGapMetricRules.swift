import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap metric must pass. Check returns its problems, or none.
    protocol CareGapMetricRule {
        func check(_ item: CareGapMetric) -> [String]
    }

    final class CareGapMetricBatchSizeRangeRule: CareGapMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapMetric) -> [String] {
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

    final class CareGapMetricCodeLengthRule: CareGapMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapMetricRequiredCodeRule: CareGapMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap metric.
    final class CareGapMetricValidator {
        var rules: [any CareGapMetricRule]

        init(rules: [any CareGapMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapMetric) -> [String] {
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

        func requireValid(_ item: CareGapMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapMetric]) -> [String: [String]] {
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

    static func defaultCareGapMetricValidator() -> CareGapMetricValidator {
        return CareGapMetricValidator(
            rules: [
                CareGapMetricBatchSizeRangeRule(min: 32, max: 80),
                CareGapMetricCodeLengthRule(maxLength: 120),
                CareGapMetricRequiredCodeRule(message: "care gap metric needs this field"),
            ]
        )
    }
}
