import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer agreement must pass. Check returns its problems, or none.
    protocol TransferAgreementRule {
        func check(_ item: TransferAgreement) -> [String]
    }

    final class TransferAgreementRequiredExternalRefRule: TransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAgreement) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferAgreementAllowedLabelRule: TransferAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class TransferAgreementCodeLengthRule: TransferAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer agreement.
    final class TransferAgreementValidator {
        var rules: [any TransferAgreementRule]

        init(rules: [any TransferAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferAgreement) -> [String] {
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

        func requireValid(_ item: TransferAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferAgreement]) -> [String: [String]] {
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

    static func defaultTransferAgreementValidator() -> TransferAgreementValidator {
        return TransferAgreementValidator(
            rules: [
                TransferAgreementRequiredExternalRefRule(message: "transfer agreement needs an entry"),
                TransferAgreementAllowedLabelRule(allowed: ["rolling", "primary"]),
                TransferAgreementCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
