import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional revocation agreement must pass. Check returns its problems, or none.
    protocol RegionalRevocationAgreementRule {
        func check(_ item: RegionalRevocationAgreement) -> [String]
    }

    final class RegionalRevocationAgreementMaximumRangeRule: RegionalRevocationAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRevocationAgreement) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRevocationAgreementLabelLengthRule: RegionalRevocationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRevocationAgreementRequiredSpecialtyRule: RegionalRevocationAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationAgreement) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional revocation agreement.
    final class RegionalRevocationAgreementValidator {
        var rules: [any RegionalRevocationAgreementRule]

        init(rules: [any RegionalRevocationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRevocationAgreement) -> [String] {
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

        func requireValid(_ item: RegionalRevocationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRevocationAgreement]) -> [String: [String]] {
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

    static func defaultRegionalRevocationAgreementValidator() -> RegionalRevocationAgreementValidator {
        return RegionalRevocationAgreementValidator(
            rules: [
                RegionalRevocationAgreementMaximumRangeRule(min: 7.8, max: 312.1),
                RegionalRevocationAgreementLabelLengthRule(maxLength: 120),
                RegionalRevocationAgreementRequiredSpecialtyRule(
                    message: "regional revocation agreement needs this field"
                ),
            ]
        )
    }
}
