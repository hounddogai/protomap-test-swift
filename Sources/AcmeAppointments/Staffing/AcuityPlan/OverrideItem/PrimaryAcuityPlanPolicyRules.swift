import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan policy must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanPolicyRule {
        func check(_ item: PrimaryAcuityPlanPolicy) -> [String]
    }

    final class PrimaryAcuityPlanPolicyAllowedCodeRule: PrimaryAcuityPlanPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanPolicyRequiredCodeRule: PrimaryAcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanPolicyRequiredCategoryRule: PrimaryAcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanPolicyBudgetRangeRule: PrimaryAcuityPlanPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryAcuityPlanPolicyLabelLengthRule: PrimaryAcuityPlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanPolicyApprovedGuardRule: PrimaryAcuityPlanPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            if item.approved && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a primary acuity plan policy.
    final class PrimaryAcuityPlanPolicyValidator {
        var rules: [any PrimaryAcuityPlanPolicyRule]

        init(rules: [any PrimaryAcuityPlanPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryAcuityPlanPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanPolicy]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanPolicyValidator() -> PrimaryAcuityPlanPolicyValidator {
        return PrimaryAcuityPlanPolicyValidator(
            rules: [
                PrimaryAcuityPlanPolicyAllowedCodeRule(allowed: []),
                PrimaryAcuityPlanPolicyRequiredCodeRule(message: "primary acuity plan policy needs a value"),
                PrimaryAcuityPlanPolicyRequiredCategoryRule(message: "primary acuity plan policy needs a value"),
                PrimaryAcuityPlanPolicyBudgetRangeRule(min: 9.0, max: 520.0),
                PrimaryAcuityPlanPolicyLabelLengthRule(maxLength: 64),
                PrimaryAcuityPlanPolicyApprovedGuardRule(limit: 8.9),
            ]
        )
    }
}
