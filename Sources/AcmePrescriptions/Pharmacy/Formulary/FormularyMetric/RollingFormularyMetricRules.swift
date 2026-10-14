import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling formulary metric must pass. Check returns its problems, or none.
    protocol RollingFormularyMetricRule {
        func check(_ item: RollingFormularyMetric) -> [String]
    }

    final class RollingFormularyMetricBatchSizeRangeRule: RollingFormularyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingFormularyMetric) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingFormularyMetricTitleLengthRule: RollingFormularyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularyMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFormularyMetricGraceDaysRangeRule: RollingFormularyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingFormularyMetric) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingFormularyMetricCodeLengthRule: RollingFormularyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingFormularyMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingFormularyMetricAllowedCodeRule: RollingFormularyMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingFormularyMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling formulary metric.
    final class RollingFormularyMetricValidator {
        var rules: [any RollingFormularyMetricRule]

        init(rules: [any RollingFormularyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingFormularyMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingFormularyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingFormularyMetric]) -> [String: [String]] {
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

    static func defaultRollingFormularyMetricValidator() -> RollingFormularyMetricValidator {
        return RollingFormularyMetricValidator(
            rules: [
                RollingFormularyMetricBatchSizeRangeRule(min: 16, max: 255),
                RollingFormularyMetricTitleLengthRule(maxLength: 120),
                RollingFormularyMetricGraceDaysRangeRule(min: 64, max: 3600),
                RollingFormularyMetricCodeLengthRule(maxLength: 16),
                RollingFormularyMetricAllowedCodeRule(allowed: ["regional", "scheduled", "strict"]),
            ]
        )
    }
}
