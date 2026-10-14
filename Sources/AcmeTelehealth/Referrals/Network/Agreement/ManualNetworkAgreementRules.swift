import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network agreement must pass. Check returns its problems, or none.
    protocol ManualNetworkAgreementRule {
        func check(_ item: ManualNetworkAgreement) -> [String]
    }

    final class ManualNetworkAgreementRequiredCodeRule: ManualNetworkAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkAgreementCodePrefixRule: ManualNetworkAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualNetworkAgreementRequiredDiagnosisCodeRule: ManualNetworkAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkAgreementAllowedChecksumRule: ManualNetworkAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is below minimum"]
            }
            return []
        }
    }

    final class ManualNetworkAgreementDiagnosisCodeLengthRule: ManualNetworkAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkAgreementCodeLengthRule: ManualNetworkAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network agreement.
    final class ManualNetworkAgreementValidator {
        var rules: [any ManualNetworkAgreementRule]

        init(rules: [any ManualNetworkAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkAgreement]) -> [String: [String]] {
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

    static func defaultManualNetworkAgreementValidator() -> ManualNetworkAgreementValidator {
        return ManualNetworkAgreementValidator(
            rules: [
                ManualNetworkAgreementRequiredCodeRule(message: "manual network agreement needs this field"),
                ManualNetworkAgreementCodePrefixRule(prefix: "Q"),
                ManualNetworkAgreementRequiredDiagnosisCodeRule(message: "manual network agreement needs an entry"),
                ManualNetworkAgreementAllowedChecksumRule(allowed: ["capped", "batched", "adaptive"]),
                ManualNetworkAgreementDiagnosisCodeLengthRule(maxLength: 16),
                ManualNetworkAgreementCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
