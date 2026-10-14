import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending specimen agreement must pass. Check returns its problems, or none.
    protocol PendingSpecimenAgreementRule {
        func check(_ item: PendingSpecimenAgreement) -> [String]
    }

    final class PendingSpecimenAgreementAllowedLabelRule: PendingSpecimenAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSpecimenAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class PendingSpecimenAgreementLabelLengthRule: PendingSpecimenAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSpecimenAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSpecimenAgreementRequiredCodeRule: PendingSpecimenAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending specimen agreement.
    final class PendingSpecimenAgreementValidator {
        var rules: [any PendingSpecimenAgreementRule]

        init(rules: [any PendingSpecimenAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSpecimenAgreement) -> [String] {
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

        func requireValid(_ item: PendingSpecimenAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSpecimenAgreement]) -> [String: [String]] {
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

    static func defaultPendingSpecimenAgreementValidator() -> PendingSpecimenAgreementValidator {
        return PendingSpecimenAgreementValidator(
            rules: [
                PendingSpecimenAgreementAllowedLabelRule(allowed: ["default"]),
                PendingSpecimenAgreementLabelLengthRule(maxLength: 16),
                PendingSpecimenAgreementRequiredCodeRule(message: "pending specimen agreement needs this field"),
            ]
        )
    }
}
