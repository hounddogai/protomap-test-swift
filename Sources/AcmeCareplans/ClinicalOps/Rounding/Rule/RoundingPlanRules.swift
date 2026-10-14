import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding plan must pass. Check returns its problems, or none.
    protocol RoundingPlanRule {
        func check(_ item: RoundingPlan) -> [String]
    }

    final class RoundingPlanCountryLengthRule: RoundingPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPlan) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingPlanCodeLengthRule: RoundingPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingPlanAllowedSummaryRule: RoundingPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is inconsistent"]
            }
            return []
        }
    }

    final class RoundingPlanCeilingRangeRule: RoundingPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingPlan) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingPlanRequiredCodeRule: RoundingPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingPlanSummaryLengthRule: RoundingPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingPlan) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding plan.
    final class RoundingPlanValidator {
        var rules: [any RoundingPlanRule]

        init(rules: [any RoundingPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingPlan]) -> [String: [String]] {
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

    static func defaultRoundingPlanValidator() -> RoundingPlanValidator {
        return RoundingPlanValidator(
            rules: [
                RoundingPlanCountryLengthRule(maxLength: 3600),
                RoundingPlanCodeLengthRule(maxLength: 86400),
                RoundingPlanAllowedSummaryRule(allowed: []),
                RoundingPlanCeilingRangeRule(min: 0.5, max: 4041.3),
                RoundingPlanRequiredCodeRule(message: "rounding plan needs a value"),
                RoundingPlanSummaryLengthRule(maxLength: 3600),
            ]
        )
    }
}
