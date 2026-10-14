import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert plan must pass. Check returns its problems, or none.
    protocol AlertPlanRule {
        func check(_ item: AlertPlan) -> [String]
    }

    final class AlertPlanAllowedCodeRule: AlertPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class AlertPlanClinicianIDLengthRule: AlertPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertPlan) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertPlanRequiredPayerRule: AlertPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertPlan) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertPlanRequiredTitleRule: AlertPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertPlanRateRangeRule: AlertPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertPlan) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert plan.
    final class AlertPlanValidator {
        var rules: [any AlertPlanRule]

        init(rules: [any AlertPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertPlan) -> [String] {
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

        func requireValid(_ item: AlertPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertPlan]) -> [String: [String]] {
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

    static func defaultAlertPlanValidator() -> AlertPlanValidator {
        return AlertPlanValidator(
            rules: [
                AlertPlanAllowedCodeRule(allowed: ["legacy", "batched", "fallback"]),
                AlertPlanClinicianIDLengthRule(maxLength: 64),
                AlertPlanRequiredPayerRule(message: "alert plan needs this field"),
                AlertPlanRequiredTitleRule(message: "alert plan needs a value"),
                AlertPlanRateRangeRule(min: 5.3, max: 3058.9),
            ]
        )
    }
}
