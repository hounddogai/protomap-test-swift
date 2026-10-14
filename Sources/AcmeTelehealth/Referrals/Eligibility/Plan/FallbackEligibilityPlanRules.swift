import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility plan must pass. Check returns its problems, or none.
    protocol FallbackEligibilityPlanRule {
        func check(_ item: FallbackEligibilityPlan) -> [String]
    }

    final class FallbackEligibilityPlanRequiredPayerRule: FallbackEligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityPlan) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityPlanAllowedChecksumRule: FallbackEligibilityPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackEligibilityPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is out of range"]
            }
            return []
        }
    }

    final class FallbackEligibilityPlanRequiredCodeRule: FallbackEligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityPlanRequiredLabelRule: FallbackEligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility plan.
    final class FallbackEligibilityPlanValidator {
        var rules: [any FallbackEligibilityPlanRule]

        init(rules: [any FallbackEligibilityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackEligibilityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityPlan]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityPlanValidator() -> FallbackEligibilityPlanValidator {
        return FallbackEligibilityPlanValidator(
            rules: [
                FallbackEligibilityPlanRequiredPayerRule(message: "fallback eligibility plan needs an entry"),
                FallbackEligibilityPlanAllowedChecksumRule(allowed: ["fallback", "pending"]),
                FallbackEligibilityPlanRequiredCodeRule(message: "fallback eligibility plan needs this field"),
                FallbackEligibilityPlanRequiredLabelRule(message: "fallback eligibility plan needs a value"),
            ]
        )
    }
}
