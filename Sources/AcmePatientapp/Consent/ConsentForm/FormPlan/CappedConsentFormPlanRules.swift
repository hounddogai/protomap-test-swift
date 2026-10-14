import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped consent form plan must pass. Check returns its problems, or none.
    protocol CappedConsentFormPlanRule {
        func check(_ item: CappedConsentFormPlan) -> [String]
    }

    final class CappedConsentFormPlanRequiredAllergyRule: CappedConsentFormPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedConsentFormPlan) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedConsentFormPlanRatioRangeRule: CappedConsentFormPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedConsentFormPlan) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedConsentFormPlanAllowedCodeRule: CappedConsentFormPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedConsentFormPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CappedConsentFormPlanDurationMinutesRangeRule: CappedConsentFormPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedConsentFormPlan) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped consent form plan.
    final class CappedConsentFormPlanValidator {
        var rules: [any CappedConsentFormPlanRule]

        init(rules: [any CappedConsentFormPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedConsentFormPlan) -> [String] {
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

        func requireValid(_ item: CappedConsentFormPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedConsentFormPlan]) -> [String: [String]] {
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

    static func defaultCappedConsentFormPlanValidator() -> CappedConsentFormPlanValidator {
        return CappedConsentFormPlanValidator(
            rules: [
                CappedConsentFormPlanRequiredAllergyRule(message: "capped consent form plan needs an entry"),
                CappedConsentFormPlanRatioRangeRule(min: 6.1, max: 410.7),
                CappedConsentFormPlanAllowedCodeRule(allowed: ["lenient"]),
                CappedConsentFormPlanDurationMinutesRangeRule(min: 32, max: 32),
            ]
        )
    }
}
