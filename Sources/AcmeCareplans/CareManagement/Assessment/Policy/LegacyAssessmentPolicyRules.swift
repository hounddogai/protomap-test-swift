import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy assessment policy must pass. Check returns its problems, or none.
    protocol LegacyAssessmentPolicyRule {
        func check(_ item: LegacyAssessmentPolicy) -> [String]
    }

    final class LegacyAssessmentPolicyRequiredLocaleRule: LegacyAssessmentPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentPolicy) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentPolicyRequiredCodeRule: LegacyAssessmentPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentPolicyCodePrefixRule: LegacyAssessmentPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAssessmentPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy assessment policy.
    final class LegacyAssessmentPolicyValidator {
        var rules: [any LegacyAssessmentPolicyRule]

        init(rules: [any LegacyAssessmentPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAssessmentPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAssessmentPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAssessmentPolicy]) -> [String: [String]] {
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

    static func defaultLegacyAssessmentPolicyValidator() -> LegacyAssessmentPolicyValidator {
        return LegacyAssessmentPolicyValidator(
            rules: [
                LegacyAssessmentPolicyRequiredLocaleRule(message: "legacy assessment policy needs this field"),
                LegacyAssessmentPolicyRequiredCodeRule(message: "legacy assessment policy needs this field"),
                LegacyAssessmentPolicyCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
