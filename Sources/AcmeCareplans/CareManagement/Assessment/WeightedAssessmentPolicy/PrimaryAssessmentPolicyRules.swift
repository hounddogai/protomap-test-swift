import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary assessment policy must pass. Check returns its problems, or none.
    protocol PrimaryAssessmentPolicyRule {
        func check(_ item: PrimaryAssessmentPolicy) -> [String]
    }

    final class PrimaryAssessmentPolicyRequiredNotesRule: PrimaryAssessmentPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAssessmentPolicy) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAssessmentPolicyRequiredLabelRule: PrimaryAssessmentPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAssessmentPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAssessmentPolicyNotesLengthRule: PrimaryAssessmentPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAssessmentPolicy) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAssessmentPolicyAllowedCodeRule: PrimaryAssessmentPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAssessmentPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a primary assessment policy.
    final class PrimaryAssessmentPolicyValidator {
        var rules: [any PrimaryAssessmentPolicyRule]

        init(rules: [any PrimaryAssessmentPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAssessmentPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryAssessmentPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAssessmentPolicy]) -> [String: [String]] {
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

    static func defaultPrimaryAssessmentPolicyValidator() -> PrimaryAssessmentPolicyValidator {
        return PrimaryAssessmentPolicyValidator(
            rules: [
                PrimaryAssessmentPolicyRequiredNotesRule(message: "primary assessment policy needs a value"),
                PrimaryAssessmentPolicyRequiredLabelRule(message: "primary assessment policy needs a value"),
                PrimaryAssessmentPolicyNotesLengthRule(maxLength: 16),
                PrimaryAssessmentPolicyAllowedCodeRule(allowed: ["tiered"]),
            ]
        )
    }
}
