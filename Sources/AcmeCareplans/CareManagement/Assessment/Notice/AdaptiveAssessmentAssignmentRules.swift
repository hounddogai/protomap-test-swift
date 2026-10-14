import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive assessment assignment must pass. Check returns its problems, or none.
    protocol AdaptiveAssessmentAssignmentRule {
        func check(_ item: AdaptiveAssessmentAssignment) -> [String]
    }

    final class AdaptiveAssessmentAssignmentAllowedCodeRule: AdaptiveAssessmentAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveAssessmentAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentAssignmentCodeLengthRule: AdaptiveAssessmentAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAssessmentAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAssessmentAssignmentRequiredPayerRule: AdaptiveAssessmentAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAssessmentAssignment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive assessment assignment.
    final class AdaptiveAssessmentAssignmentValidator {
        var rules: [any AdaptiveAssessmentAssignmentRule]

        init(rules: [any AdaptiveAssessmentAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAssessmentAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAssessmentAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAssessmentAssignment]) -> [String: [String]] {
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

    static func defaultAdaptiveAssessmentAssignmentValidator() -> AdaptiveAssessmentAssignmentValidator {
        return AdaptiveAssessmentAssignmentValidator(
            rules: [
                AdaptiveAssessmentAssignmentAllowedCodeRule(allowed: ["fallback"]),
                AdaptiveAssessmentAssignmentCodeLengthRule(maxLength: 32),
                AdaptiveAssessmentAssignmentRequiredPayerRule(message: "adaptive assessment assignment needs a value"),
            ]
        )
    }
}
