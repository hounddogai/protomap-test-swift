import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility digest must pass. Check returns its problems, or none.
    protocol FallbackEligibilityDigestRule {
        func check(_ item: FallbackEligibilityDigest) -> [String]
    }

    final class FallbackEligibilityDigestRequiredLabelRule: FallbackEligibilityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityDigestDiagnosisCodeLengthRule: FallbackEligibilityDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityDigest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackEligibilityDigestCodePrefixRule: FallbackEligibilityDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackEligibilityDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackEligibilityDigestRequiredChecksumRule: FallbackEligibilityDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityDigest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility digest.
    final class FallbackEligibilityDigestValidator {
        var rules: [any FallbackEligibilityDigestRule]

        init(rules: [any FallbackEligibilityDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackEligibilityDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityDigest]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityDigestValidator() -> FallbackEligibilityDigestValidator {
        return FallbackEligibilityDigestValidator(
            rules: [
                FallbackEligibilityDigestRequiredLabelRule(message: "fallback eligibility digest needs an entry"),
                FallbackEligibilityDigestDiagnosisCodeLengthRule(maxLength: 3600),
                FallbackEligibilityDigestCodePrefixRule(prefix: "Q"),
                FallbackEligibilityDigestRequiredChecksumRule(message: "fallback eligibility digest needs this field"),
            ]
        )
    }
}
