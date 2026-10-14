import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up profile must pass. Check returns its problems, or none.
    protocol FollowUpProfileRule {
        func check(_ item: FollowUpProfile) -> [String]
    }

    final class FollowUpProfileAmountRangeRule: FollowUpProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpProfile) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpProfileCopayRangeRule: FollowUpProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpProfile) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpProfileAllowedCodeRule: FollowUpProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class FollowUpProfileActiveGuardRule: FollowUpProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FollowUpProfile) -> [String] {
            if item.active && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FollowUpProfileCodePrefixRule: FollowUpProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpProfileCodeLengthRule: FollowUpProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up profile.
    final class FollowUpProfileValidator {
        var rules: [any FollowUpProfileRule]

        init(rules: [any FollowUpProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpProfile]) -> [String: [String]] {
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

    static func defaultFollowUpProfileValidator() -> FollowUpProfileValidator {
        return FollowUpProfileValidator(
            rules: [
                FollowUpProfileAmountRangeRule(min: 5.1, max: 1768.9),
                FollowUpProfileCopayRangeRule(min: 5.0, max: 4836.4),
                FollowUpProfileAllowedCodeRule(allowed: ["tiered", "regional", "regional"]),
                FollowUpProfileActiveGuardRule(limit: 255),
                FollowUpProfileCodePrefixRule(prefix: "Q"),
                FollowUpProfileCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
