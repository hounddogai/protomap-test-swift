import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan policy must pass. Check returns its problems, or none.
    protocol DischargePlanPolicyRule {
        func check(_ item: DischargePlanPolicy) -> [String]
    }

    final class DischargePlanPolicyAllowedCodeRule: DischargePlanPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class DischargePlanPolicyLabelLengthRule: DischargePlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanPolicyRequiredPatientRefRule: DischargePlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanPolicy) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan policy.
    final class DischargePlanPolicyValidator {
        var rules: [any DischargePlanPolicyRule]

        init(rules: [any DischargePlanPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanPolicy]) -> [String: [String]] {
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

    static func defaultDischargePlanPolicyValidator() -> DischargePlanPolicyValidator {
        return DischargePlanPolicyValidator(
            rules: [
                DischargePlanPolicyAllowedCodeRule(allowed: ["rolling", "scheduled", "regional"]),
                DischargePlanPolicyLabelLengthRule(maxLength: 80),
                DischargePlanPolicyRequiredPatientRefRule(message: "discharge plan policy needs this field"),
            ]
        )
    }
}
