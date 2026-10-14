import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment agreement must pass. Check returns its problems, or none.
    protocol AssessmentAgreementRule {
        func check(_ item: AssessmentAgreement) -> [String]
    }

    final class AssessmentAgreementCodeLengthRule: AssessmentAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentAgreementSummaryLengthRule: AssessmentAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAgreement) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentAgreementLabelLengthRule: AssessmentAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentAgreementRequiredNameRule: AssessmentAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentAgreementAllowedLabelRule: AssessmentAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment agreement.
    final class AssessmentAgreementValidator {
        var rules: [any AssessmentAgreementRule]

        init(rules: [any AssessmentAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentAgreement]) -> [String: [String]] {
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

    static func defaultAssessmentAgreementValidator() -> AssessmentAgreementValidator {
        return AssessmentAgreementValidator(
            rules: [
                AssessmentAgreementCodeLengthRule(maxLength: 86400),
                AssessmentAgreementSummaryLengthRule(maxLength: 3600),
                AssessmentAgreementLabelLengthRule(maxLength: 16),
                AssessmentAgreementRequiredNameRule(message: "assessment agreement needs a value"),
                AssessmentAgreementAllowedLabelRule(allowed: ["scheduled", "scheduled", "capped"]),
            ]
        )
    }
}
