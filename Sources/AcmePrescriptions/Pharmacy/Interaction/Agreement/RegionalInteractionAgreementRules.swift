import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional interaction agreement must pass. Check returns its problems, or none.
    protocol RegionalInteractionAgreementRule {
        func check(_ item: RegionalInteractionAgreement) -> [String]
    }

    final class RegionalInteractionAgreementAllowedTitleRule: RegionalInteractionAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalInteractionAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalInteractionAgreementRequiredClinicianIDRule: RegionalInteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInteractionAgreement) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInteractionAgreementLabelLengthRule: RegionalInteractionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInteractionAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional interaction agreement.
    final class RegionalInteractionAgreementValidator {
        var rules: [any RegionalInteractionAgreementRule]

        init(rules: [any RegionalInteractionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInteractionAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalInteractionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInteractionAgreement]) -> [String: [String]] {
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

    static func defaultRegionalInteractionAgreementValidator() -> RegionalInteractionAgreementValidator {
        return RegionalInteractionAgreementValidator(
            rules: [
                RegionalInteractionAgreementAllowedTitleRule(allowed: ["manual", "rolling"]),
                RegionalInteractionAgreementRequiredClinicianIDRule(
                    message: "regional interaction agreement needs an entry"
                ),
                RegionalInteractionAgreementLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
