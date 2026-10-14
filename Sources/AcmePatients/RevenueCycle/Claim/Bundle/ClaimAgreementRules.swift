import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim agreement must pass. Check returns its problems, or none.
    protocol ClaimAgreementRule {
        func check(_ item: ClaimAgreement) -> [String]
    }

    final class ClaimAgreementNameLengthRule: ClaimAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimAgreementCodePrefixRule: ClaimAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimAgreementAllowedCodeRule: ClaimAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class ClaimAgreementCodeLengthRule: ClaimAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimAgreementEncounterIDLengthRule: ClaimAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAgreement) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim agreement.
    final class ClaimAgreementValidator {
        var rules: [any ClaimAgreementRule]

        init(rules: [any ClaimAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimAgreement) -> [String] {
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

        func requireValid(_ item: ClaimAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimAgreement]) -> [String: [String]] {
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

    static func defaultClaimAgreementValidator() -> ClaimAgreementValidator {
        return ClaimAgreementValidator(
            rules: [
                ClaimAgreementNameLengthRule(maxLength: 255),
                ClaimAgreementCodePrefixRule(prefix: "X"),
                ClaimAgreementAllowedCodeRule(allowed: []),
                ClaimAgreementCodeLengthRule(maxLength: 32),
                ClaimAgreementEncounterIDLengthRule(maxLength: 32),
            ]
        )
    }
}
