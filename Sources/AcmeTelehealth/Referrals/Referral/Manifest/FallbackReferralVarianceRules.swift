import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback referral variance must pass. Check returns its problems, or none.
    protocol FallbackReferralVarianceRule {
        func check(_ item: FallbackReferralVariance) -> [String]
    }

    final class FallbackReferralVarianceRequiredWardRule: FallbackReferralVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferralVariance) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferralVarianceCodePrefixRule: FallbackReferralVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackReferralVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackReferralVarianceWardLengthRule: FallbackReferralVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralVariance) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralVarianceChecksumLengthRule: FallbackReferralVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralVariance) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralVarianceAllowedLabelRule: FallbackReferralVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackReferralVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback referral variance.
    final class FallbackReferralVarianceValidator {
        var rules: [any FallbackReferralVarianceRule]

        init(rules: [any FallbackReferralVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferralVariance) -> [String] {
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

        func requireValid(_ item: FallbackReferralVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferralVariance]) -> [String: [String]] {
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

    static func defaultFallbackReferralVarianceValidator() -> FallbackReferralVarianceValidator {
        return FallbackReferralVarianceValidator(
            rules: [
                FallbackReferralVarianceRequiredWardRule(message: "fallback referral variance needs this field"),
                FallbackReferralVarianceCodePrefixRule(prefix: "OPS"),
                FallbackReferralVarianceWardLengthRule(maxLength: 1000),
                FallbackReferralVarianceChecksumLengthRule(maxLength: 86400),
                FallbackReferralVarianceAllowedLabelRule(allowed: ["legacy"]),
            ]
        )
    }
}
