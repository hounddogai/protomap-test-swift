import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient result metric must pass. Check returns its problems, or none.
    protocol LenientResultMetricRule {
        func check(_ item: LenientResultMetric) -> [String]
    }

    final class LenientResultMetricBatchSizeRangeRule: LenientResultMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientResultMetric) -> [String] {
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

    final class LenientResultMetricMarginRangeRule: LenientResultMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientResultMetric) -> [String] {
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

    final class LenientResultMetricCodeLengthRule: LenientResultMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientResultMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientResultMetricRequiredNameRule: LenientResultMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientResultMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientResultMetricSegmentLengthRule: LenientResultMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientResultMetric) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient result metric.
    final class LenientResultMetricValidator {
        var rules: [any LenientResultMetricRule]

        init(rules: [any LenientResultMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientResultMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientResultMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientResultMetric]) -> [String: [String]] {
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

    static func defaultLenientResultMetricValidator() -> LenientResultMetricValidator {
        return LenientResultMetricValidator(
            rules: [
                LenientResultMetricBatchSizeRangeRule(min: 120, max: 86400),
                LenientResultMetricMarginRangeRule(min: 0.7, max: 4724.8),
                LenientResultMetricCodeLengthRule(maxLength: 86400),
                LenientResultMetricRequiredNameRule(message: "lenient result metric needs this field"),
                LenientResultMetricSegmentLengthRule(maxLength: 16),
            ]
        )
    }
}
