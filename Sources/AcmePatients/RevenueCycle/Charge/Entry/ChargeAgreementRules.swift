import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge agreement must pass. Check returns its problems, or none.
    protocol ChargeAgreementRule {
        func check(_ item: ChargeAgreement) -> [String]
    }

    final class ChargeAgreementRequiredRegionRule: ChargeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAgreement) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeAgreementAllowedCodeRule: ChargeAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ChargeAgreementCodePrefixRule: ChargeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeAgreementCodeLengthRule: ChargeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge agreement.
    final class ChargeAgreementValidator {
        var rules: [any ChargeAgreementRule]

        init(rules: [any ChargeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeAgreement]) -> [String: [String]] {
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

    static func defaultChargeAgreementValidator() -> ChargeAgreementValidator {
        return ChargeAgreementValidator(
            rules: [
                ChargeAgreementRequiredRegionRule(message: "charge agreement needs a value"),
                ChargeAgreementAllowedCodeRule(allowed: []),
                ChargeAgreementCodePrefixRule(prefix: "REF"),
                ChargeAgreementCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
