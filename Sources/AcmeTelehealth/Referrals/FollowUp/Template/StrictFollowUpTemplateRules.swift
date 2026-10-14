import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict follow up template must pass. Check returns its problems, or none.
    protocol StrictFollowUpTemplateRule {
        func check(_ item: StrictFollowUpTemplate) -> [String]
    }

    final class StrictFollowUpTemplateDiscountRangeRule: StrictFollowUpTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpTemplate) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictFollowUpTemplateAcuityRangeRule: StrictFollowUpTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpTemplate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictFollowUpTemplateCreatedAtRangeRule: StrictFollowUpTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpTemplate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictFollowUpTemplateAllowedCodeRule: StrictFollowUpTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictFollowUpTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a strict follow up template.
    final class StrictFollowUpTemplateValidator {
        var rules: [any StrictFollowUpTemplateRule]

        init(rules: [any StrictFollowUpTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFollowUpTemplate) -> [String] {
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

        func requireValid(_ item: StrictFollowUpTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFollowUpTemplate]) -> [String: [String]] {
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

    static func defaultStrictFollowUpTemplateValidator() -> StrictFollowUpTemplateValidator {
        return StrictFollowUpTemplateValidator(
            rules: [
                StrictFollowUpTemplateDiscountRangeRule(min: 1.7, max: 1347.7),
                StrictFollowUpTemplateAcuityRangeRule(min: 32, max: 64),
                StrictFollowUpTemplateCreatedAtRangeRule(min: 16, max: 120),
                StrictFollowUpTemplateAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
