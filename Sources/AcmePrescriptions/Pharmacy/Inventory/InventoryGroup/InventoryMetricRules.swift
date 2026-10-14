import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory metric must pass. Check returns its problems, or none.
    protocol InventoryMetricRule {
        func check(_ item: InventoryMetric) -> [String]
    }

    final class InventoryMetricRefillsRangeRule: InventoryMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryMetric) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryMetricRequiredCodeRule: InventoryMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryMetricAllowedCodeRule: InventoryMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class InventoryMetricRequiredSourceRule: InventoryMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryMetric) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory metric.
    final class InventoryMetricValidator {
        var rules: [any InventoryMetricRule]

        init(rules: [any InventoryMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryMetric]) -> [String: [String]] {
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

    static func defaultInventoryMetricValidator() -> InventoryMetricValidator {
        return InventoryMetricValidator(
            rules: [
                InventoryMetricRefillsRangeRule(min: 86400, max: 86400),
                InventoryMetricRequiredCodeRule(message: "inventory metric needs this field"),
                InventoryMetricAllowedCodeRule(allowed: []),
                InventoryMetricRequiredSourceRule(message: "inventory metric needs a value"),
            ]
        )
    }
}
