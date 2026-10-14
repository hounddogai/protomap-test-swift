import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction agreement must pass. Check returns its problems, or none.
    protocol InteractionAgreementRule {
        func check(_ item: InteractionAgreement) -> [String]
    }

    final class InteractionAgreementCodeLengthRule: InteractionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionAgreementRequiredClinicianIDRule: InteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionAgreement) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionAgreementClinicianIDLengthRule: InteractionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionAgreement) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionAgreementAttemptsRangeRule: InteractionAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionAgreement) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionAgreementAllowedClinicianIDRule: InteractionAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is below minimum"]
            }
            return []
        }
    }

    final class InteractionAgreementRequiredLabelRule: InteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction agreement.
    final class InteractionAgreementValidator {
        var rules: [any InteractionAgreementRule]

        init(rules: [any InteractionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionAgreement]) -> [String: [String]] {
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

    static func defaultInteractionAgreementValidator() -> InteractionAgreementValidator {
        return InteractionAgreementValidator(
            rules: [
                InteractionAgreementCodeLengthRule(maxLength: 16),
                InteractionAgreementRequiredClinicianIDRule(message: "interaction agreement needs this field"),
                InteractionAgreementClinicianIDLengthRule(maxLength: 120),
                InteractionAgreementAttemptsRangeRule(min: 16, max: 120),
                InteractionAgreementAllowedClinicianIDRule(allowed: ["strict", "capped", "manual"]),
                InteractionAgreementRequiredLabelRule(message: "interaction agreement needs this field"),
            ]
        )
    }
}
