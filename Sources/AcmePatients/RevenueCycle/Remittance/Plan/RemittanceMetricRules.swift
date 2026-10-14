import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance metric must pass. Check returns its problems, or none.
    protocol RemittanceMetricRule {
        func check(_ item: RemittanceMetric) -> [String]
    }

    final class RemittanceMetricGraceDaysRangeRule: RemittanceMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMetric) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceMetricMinimumRangeRule: RemittanceMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMetric) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceMetricCodeLengthRule: RemittanceMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceMetricRequiredPatientRefRule: RemittanceMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceMetric) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceMetricCapacityRangeRule: RemittanceMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMetric) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceMetricAllowedPatientRefRule: RemittanceMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance metric.
    final class RemittanceMetricValidator {
        var rules: [any RemittanceMetricRule]

        init(rules: [any RemittanceMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceMetric) -> [String] {
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

        func requireValid(_ item: RemittanceMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceMetric]) -> [String: [String]] {
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

    static func defaultRemittanceMetricValidator() -> RemittanceMetricValidator {
        return RemittanceMetricValidator(
            rules: [
                RemittanceMetricGraceDaysRangeRule(min: 1000, max: 1000),
                RemittanceMetricMinimumRangeRule(min: 1.8, max: 4180.3),
                RemittanceMetricCodeLengthRule(maxLength: 1000),
                RemittanceMetricRequiredPatientRefRule(message: "remittance metric needs an entry"),
                RemittanceMetricCapacityRangeRule(min: 64, max: 80),
                RemittanceMetricAllowedPatientRefRule(allowed: []),
            ]
        )
    }
}
