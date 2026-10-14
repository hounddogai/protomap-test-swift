import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling care protocol agreement must pass. Check returns its problems, or none.
    protocol RollingCareProtocolAgreementRule {
        func check(_ item: RollingCareProtocolAgreement) -> [String]
    }

    final class RollingCareProtocolAgreementLabelLengthRule: RollingCareProtocolAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAgreementAllergyLengthRule: RollingCareProtocolAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAgreement) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAgreementCodePrefixRule: RollingCareProtocolAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCareProtocolAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol agreement.
    final class RollingCareProtocolAgreementValidator {
        var rules: [any RollingCareProtocolAgreementRule]

        init(rules: [any RollingCareProtocolAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolAgreement]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolAgreementValidator() -> RollingCareProtocolAgreementValidator {
        return RollingCareProtocolAgreementValidator(
            rules: [
                RollingCareProtocolAgreementLabelLengthRule(maxLength: 1000),
                RollingCareProtocolAgreementAllergyLengthRule(maxLength: 64),
                RollingCareProtocolAgreementCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
