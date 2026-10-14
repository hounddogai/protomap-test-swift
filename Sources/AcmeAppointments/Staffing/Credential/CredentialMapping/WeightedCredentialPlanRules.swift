import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential plan must pass. Check returns its problems, or none.
    protocol WeightedCredentialPlanRule {
        func check(_ item: WeightedCredentialPlan) -> [String]
    }

    final class WeightedCredentialPlanMinimumRangeRule: WeightedCredentialPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialPlan) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCredentialPlanNameLengthRule: WeightedCredentialPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialPlanRegionLengthRule: WeightedCredentialPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialPlan) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialPlanCodePrefixRule: WeightedCredentialPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCredentialPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCredentialPlanStartsAtRangeRule: WeightedCredentialPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialPlan) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted credential plan.
    final class WeightedCredentialPlanValidator {
        var rules: [any WeightedCredentialPlanRule]

        init(rules: [any WeightedCredentialPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialPlan) -> [String] {
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

        func requireValid(_ item: WeightedCredentialPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialPlan]) -> [String: [String]] {
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

    static func defaultWeightedCredentialPlanValidator() -> WeightedCredentialPlanValidator {
        return WeightedCredentialPlanValidator(
            rules: [
                WeightedCredentialPlanMinimumRangeRule(min: 6.9, max: 1877.6),
                WeightedCredentialPlanNameLengthRule(maxLength: 120),
                WeightedCredentialPlanRegionLengthRule(maxLength: 16),
                WeightedCredentialPlanCodePrefixRule(prefix: "OPS"),
                WeightedCredentialPlanStartsAtRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
