import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral budget must pass. Check returns its problems, or none.
    protocol ReferralBudgetRule {
        func check(_ item: ReferralBudget) -> [String]
    }

    final class ReferralBudgetCodeLengthRule: ReferralBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralBudgetRequiredTimezoneRule: ReferralBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralBudget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralBudgetTimezoneLengthRule: ReferralBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralBudget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralBudgetAllowedCodeRule: ReferralBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a referral budget.
    final class ReferralBudgetValidator {
        var rules: [any ReferralBudgetRule]

        init(rules: [any ReferralBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralBudget]) -> [String: [String]] {
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

    static func defaultReferralBudgetValidator() -> ReferralBudgetValidator {
        return ReferralBudgetValidator(
            rules: [
                ReferralBudgetCodeLengthRule(maxLength: 1000),
                ReferralBudgetRequiredTimezoneRule(message: "referral budget needs this field"),
                ReferralBudgetTimezoneLengthRule(maxLength: 16),
                ReferralBudgetAllowedCodeRule(allowed: ["weighted", "pending", "weighted"]),
            ]
        )
    }
}
