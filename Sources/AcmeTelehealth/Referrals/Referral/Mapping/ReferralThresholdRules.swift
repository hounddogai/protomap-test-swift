import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral threshold must pass. Check returns its problems, or none.
    protocol ReferralThresholdRule {
        func check(_ item: ReferralThreshold) -> [String]
    }

    final class ReferralThresholdSpecialtyLengthRule: ReferralThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralThreshold) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralThresholdCodePrefixRule: ReferralThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralThresholdChecksumLengthRule: ReferralThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralThreshold) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralThresholdRequiredSpecialtyRule: ReferralThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralThreshold) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralThresholdRequiredChecksumRule: ReferralThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralThreshold) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral threshold.
    final class ReferralThresholdValidator {
        var rules: [any ReferralThresholdRule]

        init(rules: [any ReferralThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralThreshold) -> [String] {
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

        func requireValid(_ item: ReferralThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralThreshold]) -> [String: [String]] {
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

    static func defaultReferralThresholdValidator() -> ReferralThresholdValidator {
        return ReferralThresholdValidator(
            rules: [
                ReferralThresholdSpecialtyLengthRule(maxLength: 120),
                ReferralThresholdCodePrefixRule(prefix: "REF"),
                ReferralThresholdChecksumLengthRule(maxLength: 16),
                ReferralThresholdRequiredSpecialtyRule(message: "referral threshold needs this field"),
                ReferralThresholdRequiredChecksumRule(message: "referral threshold needs a value"),
            ]
        )
    }
}
