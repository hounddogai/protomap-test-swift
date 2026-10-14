import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted alert plan must pass. Check returns its problems, or none.
    protocol WeightedAlertPlanRule {
        func check(_ item: WeightedAlertPlan) -> [String]
    }

    final class WeightedAlertPlanWeightRangeRule: WeightedAlertPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAlertPlanAllowedTimezoneRule: WeightedAlertPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is below minimum"]
            }
            return []
        }
    }

    final class WeightedAlertPlanWindowDaysRangeRule: WeightedAlertPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAlertPlanRequiredCodeRule: WeightedAlertPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAlertPlanTimezoneLengthRule: WeightedAlertPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAlertPlanCodeLengthRule: WeightedAlertPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAlertPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted alert plan.
    final class WeightedAlertPlanValidator {
        var rules: [any WeightedAlertPlanRule]

        init(rules: [any WeightedAlertPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAlertPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAlertPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAlertPlan]) -> [String: [String]] {
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

    static func defaultWeightedAlertPlanValidator() -> WeightedAlertPlanValidator {
        return WeightedAlertPlanValidator(
            rules: [
                WeightedAlertPlanWeightRangeRule(min: 7.7, max: 4313.0),
                WeightedAlertPlanAllowedTimezoneRule(allowed: ["manual"]),
                WeightedAlertPlanWindowDaysRangeRule(min: 3600, max: 86400),
                WeightedAlertPlanRequiredCodeRule(message: "weighted alert plan needs an entry"),
                WeightedAlertPlanTimezoneLengthRule(maxLength: 86400),
                WeightedAlertPlanCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
