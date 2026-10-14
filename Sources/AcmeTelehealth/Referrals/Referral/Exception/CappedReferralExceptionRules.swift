import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped referral exception must pass. Check returns its problems, or none.
    protocol CappedReferralExceptionRule {
        func check(_ item: CappedReferralException) -> [String]
    }

    final class CappedReferralExceptionCodePrefixRule: CappedReferralExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReferralException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedReferralExceptionDosageMgRangeRule: CappedReferralExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferralException) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReferralExceptionAllowedNameRule: CappedReferralExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedReferralException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class CappedReferralExceptionNameLengthRule: CappedReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferralException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped referral exception.
    final class CappedReferralExceptionValidator {
        var rules: [any CappedReferralExceptionRule]

        init(rules: [any CappedReferralExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferralException) -> [String] {
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

        func requireValid(_ item: CappedReferralException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferralException]) -> [String: [String]] {
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

    static func defaultCappedReferralExceptionValidator() -> CappedReferralExceptionValidator {
        return CappedReferralExceptionValidator(
            rules: [
                CappedReferralExceptionCodePrefixRule(prefix: "REF"),
                CappedReferralExceptionDosageMgRangeRule(min: 1.0, max: 249.5),
                CappedReferralExceptionAllowedNameRule(allowed: []),
                CappedReferralExceptionNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
