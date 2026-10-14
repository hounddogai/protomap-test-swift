import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted discharge plan metric must pass. Check returns its problems, or none.
    protocol WeightedDischargePlanMetricRule {
        func check(_ item: WeightedDischargePlanMetric) -> [String]
    }

    final class WeightedDischargePlanMetricCategoryLengthRule: WeightedDischargePlanMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDischargePlanMetric) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDischargePlanMetricUnitLengthRule: WeightedDischargePlanMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDischargePlanMetric) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDischargePlanMetricRequiredUnitRule: WeightedDischargePlanMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDischargePlanMetric) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedDischargePlanMetricAllowedTitleRule: WeightedDischargePlanMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedDischargePlanMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class WeightedDischargePlanMetricRequiredCodeRule: WeightedDischargePlanMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDischargePlanMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted discharge plan metric.
    final class WeightedDischargePlanMetricValidator {
        var rules: [any WeightedDischargePlanMetricRule]

        init(rules: [any WeightedDischargePlanMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDischargePlanMetric) -> [String] {
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

        func requireValid(_ item: WeightedDischargePlanMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDischargePlanMetric]) -> [String: [String]] {
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

    static func defaultWeightedDischargePlanMetricValidator() -> WeightedDischargePlanMetricValidator {
        return WeightedDischargePlanMetricValidator(
            rules: [
                WeightedDischargePlanMetricCategoryLengthRule(maxLength: 16),
                WeightedDischargePlanMetricUnitLengthRule(maxLength: 255),
                WeightedDischargePlanMetricRequiredUnitRule(message: "weighted discharge plan metric needs an entry"),
                WeightedDischargePlanMetricAllowedTitleRule(allowed: ["tiered"]),
                WeightedDischargePlanMetricRequiredCodeRule(message: "weighted discharge plan metric needs an entry"),
            ]
        )
    }
}
