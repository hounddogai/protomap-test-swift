import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional alert tier must pass. Check returns its problems, or none.
    protocol RegionalAlertTierRule {
        func check(_ item: RegionalAlertTier) -> [String]
    }

    final class RegionalAlertTierLabelLengthRule: RegionalAlertTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAlertTierNameLengthRule: RegionalAlertTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAlertTierWeightRangeRule: RegionalAlertTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAlertTier) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAlertTierCostRangeRule: RegionalAlertTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAlertTier) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional alert tier.
    final class RegionalAlertTierValidator {
        var rules: [any RegionalAlertTierRule]

        init(rules: [any RegionalAlertTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAlertTier) -> [String] {
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

        func requireValid(_ item: RegionalAlertTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAlertTier]) -> [String: [String]] {
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

    static func defaultRegionalAlertTierValidator() -> RegionalAlertTierValidator {
        return RegionalAlertTierValidator(
            rules: [
                RegionalAlertTierLabelLengthRule(maxLength: 3600),
                RegionalAlertTierNameLengthRule(maxLength: 1000),
                RegionalAlertTierWeightRangeRule(min: 3.7, max: 3563.2),
                RegionalAlertTierCostRangeRule(min: 5.6, max: 2382.8),
            ]
        )
    }
}
