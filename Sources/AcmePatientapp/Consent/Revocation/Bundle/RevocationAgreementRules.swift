import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation agreement must pass. Check returns its problems, or none.
    protocol RevocationAgreementRule {
        func check(_ item: RevocationAgreement) -> [String]
    }

    final class RevocationAgreementCodePrefixRule: RevocationAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationAgreementPinnedGuardRule: RevocationAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RevocationAgreement) -> [String] {
            if item.pinned && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RevocationAgreementBedLengthRule: RevocationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAgreement) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation agreement.
    final class RevocationAgreementValidator {
        var rules: [any RevocationAgreementRule]

        init(rules: [any RevocationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationAgreement]) -> [String: [String]] {
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

    static func defaultRevocationAgreementValidator() -> RevocationAgreementValidator {
        return RevocationAgreementValidator(
            rules: [
                RevocationAgreementCodePrefixRule(prefix: "OPS"),
                RevocationAgreementPinnedGuardRule(limit: 4.4),
                RevocationAgreementBedLengthRule(maxLength: 255),
            ]
        )
    }
}
