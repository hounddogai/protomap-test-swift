import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered referral exception must pass. Check returns its problems, or none.
    protocol TieredReferralExceptionRule {
        func check(_ item: TieredReferralException) -> [String]
    }

    final class TieredReferralExceptionSpecialtyLengthRule: TieredReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralException) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralExceptionRequiredTitleRule: TieredReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralExceptionMaximumRangeRule: TieredReferralExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferralException) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReferralExceptionCodePrefixRule: TieredReferralExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReferralException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredReferralExceptionCodeLengthRule: TieredReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralExceptionAllowedSpecialtyRule: TieredReferralExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReferralException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered referral exception.
    final class TieredReferralExceptionValidator {
        var rules: [any TieredReferralExceptionRule]

        init(rules: [any TieredReferralExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferralException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReferralException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferralException]) -> [String: [String]] {
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

    static func defaultTieredReferralExceptionValidator() -> TieredReferralExceptionValidator {
        return TieredReferralExceptionValidator(
            rules: [
                TieredReferralExceptionSpecialtyLengthRule(maxLength: 86400),
                TieredReferralExceptionRequiredTitleRule(message: "tiered referral exception needs this field"),
                TieredReferralExceptionMaximumRangeRule(min: 0.9, max: 791.8),
                TieredReferralExceptionCodePrefixRule(prefix: "X"),
                TieredReferralExceptionCodeLengthRule(maxLength: 1000),
                TieredReferralExceptionAllowedSpecialtyRule(allowed: []),
            ]
        )
    }
}
