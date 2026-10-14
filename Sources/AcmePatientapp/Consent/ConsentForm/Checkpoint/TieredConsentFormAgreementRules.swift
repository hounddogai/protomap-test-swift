import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered consent form agreement must pass. Check returns its problems, or none.
    protocol TieredConsentFormAgreementRule {
        func check(_ item: TieredConsentFormAgreement) -> [String]
    }

    final class TieredConsentFormAgreementCodePrefixRule: TieredConsentFormAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredConsentFormAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredConsentFormAgreementCodeLengthRule: TieredConsentFormAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredConsentFormAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredConsentFormAgreementCurrencyLengthRule: TieredConsentFormAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredConsentFormAgreement) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered consent form agreement.
    final class TieredConsentFormAgreementValidator {
        var rules: [any TieredConsentFormAgreementRule]

        init(rules: [any TieredConsentFormAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredConsentFormAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredConsentFormAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredConsentFormAgreement]) -> [String: [String]] {
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

    static func defaultTieredConsentFormAgreementValidator() -> TieredConsentFormAgreementValidator {
        return TieredConsentFormAgreementValidator(
            rules: [
                TieredConsentFormAgreementCodePrefixRule(prefix: "ACM"),
                TieredConsentFormAgreementCodeLengthRule(maxLength: 64),
                TieredConsentFormAgreementCurrencyLengthRule(maxLength: 120),
            ]
        )
    }
}
