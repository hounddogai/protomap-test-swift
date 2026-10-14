import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility plan must pass. Check returns its problems, or none.
    protocol EligibilityPlanRule {
        func check(_ item: EligibilityPlan) -> [String]
    }

    final class EligibilityPlanRequiredPatientRefRule: EligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityPlan) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityPlanCodePrefixRule: EligibilityPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityPlanPatientRefLengthRule: EligibilityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPlan) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility plan.
    final class EligibilityPlanValidator {
        var rules: [any EligibilityPlanRule]

        init(rules: [any EligibilityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityPlan) -> [String] {
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

        func requireValid(_ item: EligibilityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityPlan]) -> [String: [String]] {
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

    static func defaultEligibilityPlanValidator() -> EligibilityPlanValidator {
        return EligibilityPlanValidator(
            rules: [
                EligibilityPlanRequiredPatientRefRule(message: "eligibility plan needs this field"),
                EligibilityPlanCodePrefixRule(prefix: "Q"),
                EligibilityPlanPatientRefLengthRule(maxLength: 80),
            ]
        )
    }
}
