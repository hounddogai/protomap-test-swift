import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending overtime metric must pass. Check returns its problems, or none.
    protocol PendingOvertimeMetricRule {
        func check(_ item: PendingOvertimeMetric) -> [String]
    }

    final class PendingOvertimeMetricCodeLengthRule: PendingOvertimeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOvertimeMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOvertimeMetricCapacityRangeRule: PendingOvertimeMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeMetric) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingOvertimeMetricAcuityRangeRule: PendingOvertimeMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeMetric) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending overtime metric.
    final class PendingOvertimeMetricValidator {
        var rules: [any PendingOvertimeMetricRule]

        init(rules: [any PendingOvertimeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOvertimeMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingOvertimeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOvertimeMetric]) -> [String: [String]] {
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

    static func defaultPendingOvertimeMetricValidator() -> PendingOvertimeMetricValidator {
        return PendingOvertimeMetricValidator(
            rules: [
                PendingOvertimeMetricCodeLengthRule(maxLength: 64),
                PendingOvertimeMetricCapacityRangeRule(min: 64, max: 80),
                PendingOvertimeMetricAcuityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
