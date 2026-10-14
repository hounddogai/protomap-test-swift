import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback transfer metric must pass. Check returns its problems, or none.
    protocol FallbackTransferMetricRule {
        func check(_ item: FallbackTransferMetric) -> [String]
    }

    final class FallbackTransferMetricRequiredLabelRule: FallbackTransferMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackTransferMetricCopayRangeRule: FallbackTransferMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferMetric) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackTransferMetricRequiredCodeRule: FallbackTransferMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback transfer metric.
    final class FallbackTransferMetricValidator {
        var rules: [any FallbackTransferMetricRule]

        init(rules: [any FallbackTransferMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTransferMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackTransferMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTransferMetric]) -> [String: [String]] {
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

    static func defaultFallbackTransferMetricValidator() -> FallbackTransferMetricValidator {
        return FallbackTransferMetricValidator(
            rules: [
                FallbackTransferMetricRequiredLabelRule(message: "fallback transfer metric needs this field"),
                FallbackTransferMetricCopayRangeRule(min: 3.2, max: 4596.0),
                FallbackTransferMetricRequiredCodeRule(message: "fallback transfer metric needs this field"),
            ]
        )
    }
}
