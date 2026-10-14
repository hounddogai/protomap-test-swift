import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient acuity plan policy must pass. Check returns its problems, or none.
    protocol LenientAcuityPlanPolicyRule {
        func check(_ item: LenientAcuityPlanPolicy) -> [String]
    }

    final class LenientAcuityPlanPolicyRequiredSummaryRule: LenientAcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAcuityPlanPolicyAllowedSummaryRule: LenientAcuityPlanPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is inconsistent"]
            }
            return []
        }
    }

    final class LenientAcuityPlanPolicyRequiredLabelRule: LenientAcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAcuityPlanPolicyRequiredCodeRule: LenientAcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAcuityPlanPolicyVisibleGuardRule: LenientAcuityPlanPolicyRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            if item.visible && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class LenientAcuityPlanPolicyDosageMgRangeRule: LenientAcuityPlanPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAcuityPlanPolicy) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient acuity plan policy.
    final class LenientAcuityPlanPolicyValidator {
        var rules: [any LenientAcuityPlanPolicyRule]

        init(rules: [any LenientAcuityPlanPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAcuityPlanPolicy) -> [String] {
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

        func requireValid(_ item: LenientAcuityPlanPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAcuityPlanPolicy]) -> [String: [String]] {
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

    static func defaultLenientAcuityPlanPolicyValidator() -> LenientAcuityPlanPolicyValidator {
        return LenientAcuityPlanPolicyValidator(
            rules: [
                LenientAcuityPlanPolicyRequiredSummaryRule(message: "lenient acuity plan policy needs an entry"),
                LenientAcuityPlanPolicyAllowedSummaryRule(allowed: ["primary"]),
                LenientAcuityPlanPolicyRequiredLabelRule(message: "lenient acuity plan policy needs an entry"),
                LenientAcuityPlanPolicyRequiredCodeRule(message: "lenient acuity plan policy needs this field"),
                LenientAcuityPlanPolicyVisibleGuardRule(limit: 16),
                LenientAcuityPlanPolicyDosageMgRangeRule(min: 9.1, max: 2971.3),
            ]
        )
    }
}
