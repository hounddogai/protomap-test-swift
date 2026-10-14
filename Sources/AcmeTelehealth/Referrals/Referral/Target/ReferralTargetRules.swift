import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral target must pass. Check returns its problems, or none.
    protocol ReferralTargetRule {
        func check(_ item: ReferralTarget) -> [String]
    }

    final class ReferralTargetExpiresAtRangeRule: ReferralTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralTarget) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralTargetCodePrefixRule: ReferralTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralTargetRequiredNameRule: ReferralTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralTargetRequiredCodeRule: ReferralTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralTargetAllowedNameRule: ReferralTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class ReferralTargetNameLengthRule: ReferralTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral target.
    final class ReferralTargetValidator {
        var rules: [any ReferralTargetRule]

        init(rules: [any ReferralTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralTarget) -> [String] {
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

        func requireValid(_ item: ReferralTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralTarget]) -> [String: [String]] {
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

    static func defaultReferralTargetValidator() -> ReferralTargetValidator {
        return ReferralTargetValidator(
            rules: [
                ReferralTargetExpiresAtRangeRule(min: 80, max: 1000),
                ReferralTargetCodePrefixRule(prefix: "X"),
                ReferralTargetRequiredNameRule(message: "referral target needs a value"),
                ReferralTargetRequiredCodeRule(message: "referral target needs this field"),
                ReferralTargetAllowedNameRule(allowed: ["weighted", "regional"]),
                ReferralTargetNameLengthRule(maxLength: 32),
            ]
        )
    }
}
